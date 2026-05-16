`timescale 1ns / 1ps

module sim_btn_enc;

reg clk, rst_n;
reg [1:0] btn_in;
wire [7:0] data;
wire data_valid;
wire data_ready;
wire uart_tx;

btn_enc #(.BTN_WIDTH(2)) btn_enc_inst (
    .clk(clk),
    .rst_n(rst_n),
    .btn_in(btn_in),
    .data(data),
    .data_valid(data_valid),
    .data_ready(data_ready)
);

uart_tx uart_tx_inst (
    .clk(clk),
    .rst_n(rst_n),
    .uart_tx(uart_tx),
    .data(data),
    .data_valid(data_valid),
    .data_ready(data_ready)
);

// Assuming same clock for btn_enc and uart_tx in this test
// 64x clock frequency for 115200 baudrate
always #67.817 clk = ~clk;

initial begin
    $dumpfile("sim_btn_enc.vcd");
    $dumpvars(0, sim_btn_enc);
    clk = 0;
    rst_n   = 0;
    btn_in  = 2'b00;
    #200 rst_n = 1;
    #10000;
    btn_in[0] = 1; // First click
    #90000;
    btn_in[0] = 0; // Second click after first click finish 
    #20000;
    btn_in[1] = 1; // Third click before second click finish
    #90000;
    #160000; // Ensure no more data
    #10000 $finish;
end

endmodule