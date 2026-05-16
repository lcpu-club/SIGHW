`timescale 1ns / 1ps

module sim_led_dec;

reg clk, rst_n, data_valid;
reg [7:0] data;
wire [1:0] led_out;

// 100MHz
always #5 clk = ~clk;

led_dec #(.BTN_WIDTH(2)) led_dec_inst (
    .clk(clk),
    .rst_n(rst_n),
    .data(data),
    .data_valid(data_valid),
    .led_out(led_out)
);

initial begin
    $dumpfile("sim_led_dec.vcd");
    $dumpvars(0, sim_led_dec);
    clk = 0;
    rst_n = 0;
    data = 0;
    data_valid = 0;
    #200 rst_n = 1;
    #1000;
    @(posedge clk);
    #10;
    data = 8'h41;
    data_valid = 1;
    @(posedge clk);
    #10;
    data_valid = 0;
    #1000;
    @(posedge clk);
    #10;
    data = 8'h43;
    data_valid = 1;
    @(posedge clk);
    #10;
    data_valid = 0;
    #1000 $finish;
end
endmodule