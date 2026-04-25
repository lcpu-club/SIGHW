`timescale 1ns / 1ns

module debounce (
    input wire clk,
    input wire rst_n,
    input wire button_in,
    output reg button_out
);

parameter DEBOUNCE_COUNT = 10'd12500000;

reg [32:0] debouncer_cnt;
reg button_reg;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        debouncer_cnt <= 0;
        button_reg <= 0;
        button_out <= 0;
    end else begin
        if (button_in != button_reg) begin
            debouncer_cnt <= debouncer_cnt + 1;
            if (debouncer_cnt >= DEBOUNCE_COUNT) begin
                button_reg <= button_in;
                button_out <= button_in;
                debouncer_cnt <= 0;
            end
        end else begin 
            debouncer_cnt <= 0;
        end
    end
end

endmodule 