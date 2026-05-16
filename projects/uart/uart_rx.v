`timescale 1ns / 1ps

module uart_rx(
    input clk,
    input rst_n,
    input uart_rx,
    output [7:0] data,
    output data_valid
    );

reg [9:0] counter;
reg [9:0] data_buf;
wire counter_rx;

assign counter_rx = (counter[5:0] == 6'b100000);
assign data_valid = counter == 10'd1;
assign data = data_buf[8:1];

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        counter <= 10'd0;
        data_buf <= 10'd0;
    end else begin
        if (counter > 10'd0)
            counter <= counter - 10'd1;
        else if (uart_rx == 1'b0)
            counter <= 10'd639;
        else
            counter <= 10'd0;
        if (counter_rx)
            data_buf <= {uart_rx, data_buf[9:1]};
        else
            data_buf <= data_buf;
    end
end

endmodule

