`timescale 1ns / 1ps

module sim_btn_debounce;

reg clk, rst_n;
reg [1:0] button_in;
wire [1:0] button_out;

// Recuded debounce count for faster simulation
btn_debounce #(.DEBOUNCE_COUNT(125)) btn_debounce_inst_0 (
    .clk(clk),
    .rst_n(rst_n),
    .button_in(button_in[0]),
    .button_out(button_out[0])
);

// Recuded debounce count for faster simulation
btn_debounce #(.DEBOUNCE_COUNT(125)) btn_debounce_inst_1 (
    .clk(clk),
    .rst_n(rst_n),
    .button_in(button_in[1]),
    .button_out(button_out[1])
);

// 100 MHz
always #5 clk = ~clk;

integer n, i;

initial begin
    $dumpfile("sim_btn_debounce.vcd");
    $dumpvars(0, sim_btn_debounce);
    clk = 0;
    rst_n = 0;
    button_in = 2'b10;
    #100 rst_n = 1;
    #2000
    #($urandom_range(300, 800)) button_in = ~button_in;
    n = $urandom_range(2, 5) * 2;
    for (i = 0; i < n; i = i + 1) begin
        #($urandom_range(30, 80)) button_in = ~button_in;
    end
    #5000
    #($urandom_range(300, 800)) button_in = ~button_in;
    n = $urandom_range(2, 5) * 2;
    for (i = 0; i < n; i = i + 1) begin
        #($urandom_range(30, 80)) button_in = ~button_in;
    end
    #5000 $finish;
end

endmodule
