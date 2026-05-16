`timescale 1ns / 1ps

module sim_uart_rx;

reg clk, rst_n;
reg uart_rx;
wire [7:0] data;
wire data_valid;

uart_rx uart_rx_inst (
    .clk(clk),
    .rst_n(rst_n),
    .uart_rx(uart_rx),
    .data(data),
    .data_valid(data_valid)
);

// 64x clock frequency for 115200 baudrate
always #67.817 clk = ~clk;

task send_byte(input [7:0] data);
    integer i;
    begin
        uart_rx = 0;
        #(67*2*64);
        for (i = 0; i < 8; i = i + 1) begin
            uart_rx = data[i];
            #(67*2*64);
        end
        uart_rx = 1;
        #(67*2*64);
    end
endtask

initial begin
    $dumpfile("sim_uart_rx.vcd");
    $dumpvars(0, sim_uart_rx);
    clk = 0;
    rst_n = 0;
    uart_rx = 1;
    #200 rst_n = 1;
    #10000 // Test first character A
    send_byte(8'h41);
    #10000 // Test Second character B
    send_byte(8'h42);
    #160000; // Ensure no more characters
    #10000 $finish;
end

endmodule
