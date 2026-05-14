`timescale 1ns / 1ps

module sim_uart_tx;

reg clk, rst_n;
reg [7:0] data;
reg data_valid;
wire data_ready, uart_tx;

uart_tx uart_tx_inst (
    .clk(clk),
    .rst_n(rst_n),
    .data(data),
    .data_valid(data_valid),
    .data_ready(data_ready),
    .uart_tx(uart_tx)
);

// 64x clock frequency for 115200 baudrate
always #67.817 clk = ~clk;

initial begin
    $dumpfile("sim_uart_tx.vcd");
    $dumpvars(0, sim_uart_tx);
    clk = 0;
    rst_n = 0;
    data = 0;
    data_valid = 0;
    #200 rst_n = 1;
    #10000;
    // First character A
    @(posedge clk)
    #1 data = 8'h41;
    data_valid = 1;
    // Second character B, data valid before ready 
    @(posedge clk)
    #1 data = 8'h42;
    @(posedge clk)
    wait(data_ready == 1); // Wait for data consumption
    @(posedge clk)
    #1 data_valid = 0;
    wait(data_ready == 1); // Wait for transmit finish
    #10000;
    // Third character C, data valid after ready
    @(posedge clk)
    #1 data = 8'h43;
    data_valid = 1;
    @(posedge clk)
    wait(data_ready == 1); // Wait for data consumption
    @(posedge clk)
    #1 data_valid = 0;
    wait(data_ready == 1); // Wait for transmit finish
    #10000 $finish;
end

endmodule
