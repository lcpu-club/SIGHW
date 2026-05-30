// =============================================================================
// AXI4-Lite 内存读写测试模块
// 功能：从地址 0 到 1GB，顺序写入递增数列，写完后逐一读回验证
// 总线：32-bit 数据，32-bit 地址
// 错误处理：读写不匹配时拉高 error 信号并立即停止
// 注意：1GB / 4B = 256M 次事务，实际运行时间较长
// =============================================================================

module dram_test #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    // 测试地址范围：BASE_ADDR 到 BASE_ADDR + TEST_SIZE - 1
    parameter [ADDR_WIDTH-1:0] BASE_ADDR = 32'h00100000,
    parameter [ADDR_WIDTH-1:0] TEST_SIZE = 32'h08000000  // 1GB = 0x40000000 bytes
) (
    input  wire                  clk,
    input  wire                  rstn,       // 低有效复位

    // AXI4-Lite Master 接口
    // --- 写地址通道 ---
    output reg  [ADDR_WIDTH-1:0] m_axil_awaddr,
    output reg  [2:0]            m_axil_awprot,
    output reg                   m_axil_awvalid,
    input  wire                  m_axil_awready,
    // --- 写数据通道 ---
    output reg  [DATA_WIDTH-1:0] m_axil_wdata,
    output reg  [3:0]            m_axil_wstrb,
    output reg                   m_axil_wvalid,
    input  wire                  m_axil_wready,
    // --- 写响应通道 ---
    input  wire [1:0]            m_axil_bresp,
    input  wire                  m_axil_bvalid,
    output reg                   m_axil_bready,
    // --- 读地址通道 ---
    output reg  [ADDR_WIDTH-1:0] m_axil_araddr,
    output reg  [2:0]            m_axil_arprot,
    output reg                   m_axil_arvalid,
    input  wire                  m_axil_arready,
    // --- 读数据通道 ---
    input  wire [DATA_WIDTH-1:0] m_axil_rdata,
    input  wire [1:0]            m_axil_rresp,
    input  wire                  m_axil_rvalid,
    output reg                   m_axil_rready,

    // 状态输出
    output reg                   done,       // 测试完成（全部通过）
    output reg                   error,      // 读写不匹配，已停止
    output reg  [ADDR_WIDTH-1:0] error_addr, // 出错地址
    output reg  [DATA_WIDTH-1:0] error_exp,  // 期望值
    output reg  [DATA_WIDTH-1:0] error_got   // 实际读到的值
);

    // -------------------------------------------------------------------------
    // 状态机定义
    // -------------------------------------------------------------------------
    localparam [3:0]
        S_IDLE       = 4'd0,
        S_WRITE_AW   = 4'd1,   // 发写地址
        S_WRITE_W    = 4'd2,   // 发写数据
        S_WRITE_B    = 4'd3,   // 等写响应
        S_WRITE_NEXT = 4'd4,   // 更新写地址/数据，判断是否写完
        S_READ_AR    = 4'd5,   // 发读地址
        S_READ_R     = 4'd6,   // 等读数据
        S_READ_NEXT  = 4'd7,   // 更新读地址，判断是否读完
        S_DONE       = 4'd8,   // 全部通过
        S_ERROR      = 4'd9;   // 出错停止

    reg [3:0] state;

    // 当前操作的字节地址（步进 4，每次操作一个 32-bit word）
    reg [ADDR_WIDTH-1:0] cur_addr;

    // 期望的数据值（顺序递增数列，从 0 开始，每次 +1）
    // 写入时用 word index 作为数据：第 N 个 word 写入值 N
    wire [DATA_WIDTH-1:0] expect_data = cur_addr[ADDR_WIDTH-1:2]; // addr/4 = word index

    // 地址结束判断
    wire addr_done = (cur_addr >= BASE_ADDR + TEST_SIZE);

    // -------------------------------------------------------------------------
    // 主状态机
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            state           <= S_IDLE;
            cur_addr        <= BASE_ADDR;
            done            <= 1'b0;
            error           <= 1'b0;
            error_addr      <= {ADDR_WIDTH{1'b0}};
            error_exp       <= {DATA_WIDTH{1'b0}};
            error_got       <= {DATA_WIDTH{1'b0}};

            m_axil_awaddr   <= {ADDR_WIDTH{1'b0}};
            m_axil_awprot   <= 3'b000;
            m_axil_awvalid  <= 1'b0;
            m_axil_wdata    <= {DATA_WIDTH{1'b0}};
            m_axil_wstrb    <= 4'hF;
            m_axil_wvalid   <= 1'b0;
            m_axil_bready   <= 1'b0;
            m_axil_araddr   <= {ADDR_WIDTH{1'b0}};
            m_axil_arprot   <= 3'b000;
            m_axil_arvalid  <= 1'b0;
            m_axil_rready   <= 1'b0;
        end else begin
            case (state)

                // ----------------------------------------------------------
                S_IDLE: begin
                    cur_addr <= BASE_ADDR;
                    state    <= S_WRITE_AW;
                end

                // ----------------------------------------------------------
                // 写阶段：发写地址和写数据（同时发，AXI4-Lite 允许）
                // ----------------------------------------------------------
                S_WRITE_AW: begin
                    m_axil_awaddr  <= cur_addr;
                    m_axil_awvalid <= 1'b1;
                    m_axil_wdata   <= expect_data;
                    m_axil_wstrb   <= 4'hF;
                    m_axil_wvalid  <= 1'b1;
                    m_axil_bready  <= 1'b1;
                    state          <= S_WRITE_W;
                end

                S_WRITE_W: begin
                    // 等待写地址和写数据均握手完成
                    if (m_axil_awready) m_axil_awvalid <= 1'b0;
                    if (m_axil_wready)  m_axil_wvalid  <= 1'b0;

                    if ((m_axil_awready || !m_axil_awvalid) &&
                        (m_axil_wready  || !m_axil_wvalid)) begin
                        state <= S_WRITE_B;
                    end
                end

                S_WRITE_B: begin
                    // 等写响应
                    // awvalid/wvalid 可能在上一状态已清零，确保清零
                    m_axil_awvalid <= 1'b0;
                    m_axil_wvalid  <= 1'b0;
                    if (m_axil_bvalid) begin
                        m_axil_bready <= 1'b0;
                        state         <= S_WRITE_NEXT;
                    end
                end

                S_WRITE_NEXT: begin
                    // 地址步进，检查是否写完
                    cur_addr <= cur_addr + 4;
                    if (addr_done) begin
                        // 写完，切换到读阶段，重置地址
                        cur_addr <= BASE_ADDR;
                        state    <= S_READ_AR;
                    end else begin
                        state <= S_WRITE_AW;
                    end
                end

                // ----------------------------------------------------------
                // 读阶段：发读地址，等读数据，校验
                // ----------------------------------------------------------
                S_READ_AR: begin
                    m_axil_araddr  <= cur_addr;
                    m_axil_arvalid <= 1'b1;
                    m_axil_rready  <= 1'b1;
                    state          <= S_READ_R;
                end

                S_READ_R: begin
                    if (m_axil_arready) m_axil_arvalid <= 1'b0;
                    if (m_axil_rvalid) begin
                        m_axil_rready <= 1'b0;
                        if (m_axil_rdata !== expect_data) begin
                            // 数据不匹配，记录错误信息并停止
                            error      <= 1'b1;
                            error_addr <= cur_addr;
                            error_exp  <= expect_data;
                            error_got  <= m_axil_rdata;
                            state      <= S_ERROR;
                        end else begin
                            state <= S_READ_NEXT;
                        end
                    end
                end

                S_READ_NEXT: begin
                    cur_addr <= cur_addr + 4;
                    if (addr_done) begin
                        state <= S_DONE;
                    end else begin
                        state <= S_READ_AR;
                    end
                end

                // ----------------------------------------------------------
                S_DONE: begin
                    done <= 1'b1;
                end

                // ----------------------------------------------------------
                S_ERROR: begin
                    // 保持 error 信号，所有 AXI 输出清零，停止操作
                    m_axil_awvalid <= 1'b0;
                    m_axil_wvalid  <= 1'b0;
                    m_axil_bready  <= 1'b0;
                    m_axil_arvalid <= 1'b0;
                    m_axil_rready  <= 1'b0;
                end

                default: state <= S_IDLE;

            endcase
        end
    end

endmodule