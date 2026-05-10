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


always #67.817 clk = ~clk;

initial begin
    clk = 0;
    rst_n = 0;
    data = 0;
    data_valid = 0;
    #200 rst_n = 1;
    #200;
    @(posedge clk)
    #1 data = 8'h41;
    data_valid = 1;
    @(posedge clk)
    #1 data = 8'h42;
    @(posedge clk)
    wait(data_ready == 1);
    @(posedge clk)
    #1 data_valid = 0;
    #100000 $finish;
end

endmodule
