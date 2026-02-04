// Multiplexer module
module Multiplexer (
    output wire out,
    input wire select,
    input wire btn,
    input wire clk
);
    assign out = select ? btn : clk;  // Use button if select is 1, else use clk
endmodule

module decimal_counter (
    output reg [3:0] count,
    output reg carry,             // 1-cycle pulse when overflow/underflow occurs
    input wire clk,
    input wire rst,
    input wire enable,
    input wire direction          // 0 = up, 1 = down
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            count <= 4'd0;
            carry <= 1'b0;
        end else if (enable) begin
            if (direction == 1'b0) begin
                // Count UP
                if (count == 4'd9) begin
                    count <= 4'd0;
                    carry <= 1'b1;
                end else begin
                    count <= count + 4'd1;
                    carry <= 1'b0;
                end
            end else begin
                // Count DOWN
                if (count == 4'd0) begin
                    count <= 4'd9;
                    carry <= 1'b1;
                end else begin
                    count <= count - 4'd1;
                    carry <= 1'b0;
                end
            end
        end else begin
            carry <= 1'b0;
        end
    end

endmodule

module top_counter_5digit (
    input wire clk,
    input wire btn,
    input wire sel,            // Select between clk and btn
    input wire rst,
    input wire direction,      // 0 = up, 1 = down
    output wire [3:0] digit0,
    output wire [3:0] digit1,
    output wire [3:0] digit2,
    output wire [3:0] digit3,
    output wire [3:0] digit4
);

    wire clk_mux;
    wire c0, c1, c2, c3;

    // MUX to choose between clk and btn
    Multiplexer mux_inst (
        .out(clk_mux),
        .select(sel),
        .btn(btn),
        .clk(clk)
    );

    // Least significant digit (always enabled)
    decimal_counter d0 (
        .count(digit0),
        .carry(c0),
        .clk(clk_mux),
        .rst(rst),
        .enable(1'b1),
        .direction(direction)
    );

    // Higher digits only count on carry
    decimal_counter d1 (
        .count(digit1),
        .carry(c1),
        .clk(clk_mux),
        .rst(rst),
        .enable(c0),
        .direction(direction)
    );

    decimal_counter d2 (
        .count(digit2),
        .carry(c2),
        .clk(clk_mux),
        .rst(rst),
        .enable(c1),
        .direction(direction)
    );

    decimal_counter d3 (
        .count(digit3),
        .carry(c3),
        .clk(clk_mux),
        .rst(rst),
        .enable(c2),
        .direction(direction)
    );

    decimal_counter d4 (
        .count(digit4),
        .carry(),  // Not used
        .clk(clk_mux),
        .rst(rst),
        .enable(c3),
        .direction(direction)
    );

endmodule

`timescale 1ns / 1ps

module tb_top_counter_5digit;

    // Testbench signals
    reg clk;
    reg btn;
    reg sel;
    reg rst;
    reg direction;  // 0 = up, 1 = down
    wire [3:0] digit0;
    wire [3:0] digit1;
    wire [3:0] digit2;
    wire [3:0] digit3;
    wire [3:0] digit4;

    // Instantiate the top-level 5-digit counter module
    top_counter_5digit uut (
        .clk(clk),
        .btn(btn),
        .sel(sel),
        .rst(rst),
        .direction(direction),
        .digit0(digit0),
        .digit1(digit1),
        .digit2(digit2),
        .digit3(digit3),
        .digit4(digit4)
    );

    // Generate clock signal
    always begin
        #5 clk = ~clk;  // Toggle every 5ns
    end

    // Stimulus block
    initial begin
        // Initialize signals
        clk = 0;
        btn = 0;
        sel = 0;  // Use the clock as the clock source
        rst = 1;
        direction = 0;  // Start with counting up

        // Apply reset for a few clock cycles
        #10 rst = 0;

        // Test counting up (direction = 0)
        #10 direction = 0;  // Up counting
        #1000;  // Simulate counting up for a while

        // Test counting down (direction = 1)
        #10 direction = 1;  // Down counting
        #1000;  // Simulate counting down for a while

        // Change clock source to btn (sel = 1)
        #10 sel = 1;
        btn = 1;  // Simulate button press
        #10 btn = 0;  // Release button
        #10 btn = 1;  // Another button press
        #10 btn = 0;

        // Test counting up with btn as clock
        #10 direction = 0;  // Up counting
        #1000;

        // Test counting down with btn as clock
        #10 direction = 1;  // Down counting
        #1000;

        // Finish simulation
        $stop;
    end

endmodule

