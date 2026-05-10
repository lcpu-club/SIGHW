`timescale 1ns / 1ps

module uart_tx(
    input clk,
    input rst_n,
    input [7:0] data,
    input data_valid,
    output data_ready,
    output uart_tx
    );

reg [9:0] counter;
reg [9:0] data_buf;
wire counter_tx;
assign data_ready = (counter == 10'd0);
assign uart_tx = data_buf[0];
assign counter_tx = (counter[5:0] == 6'd0);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        counter <= 10'b0;
        data_buf <= 10'b1;
    end else begin
        if (data_ready) begin
            if (data_valid) begin
                counter <= 10'd639;
                data_buf <= {1'b1, data, 1'b0};
            end else begin
                counter <= counter;
                data_buf <= 10'b1;
            end
        end else begin
            counter <= counter - 10'd1;
            if (counter_tx)
                data_buf <= data_buf >> 1;
            else
                data_buf <= data_buf;
        end
    end
end

endmodule
