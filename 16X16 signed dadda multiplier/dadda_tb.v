`timescale 1ns / 1ps

module dadda_tb();
    // ---------------------------------------------------------
    // Inputs and Outputs
    // ---------------------------------------------------------
    reg [15:0] a;
    reg [15:0] b;
    wire [31:0] y; // Fixed width to match DUT (was 33 bits)

    // ---------------------------------------------------------
    // Instantiate the Unit Under Test (UUT)
    // ---------------------------------------------------------
    dadda uut (
        .a(a),
        .b(b),
        .y(y)
    );

    // ---------------------------------------------------------
    // Test Procedure
    // ---------------------------------------------------------
    initial begin
        // Initialize Inputs
        a = 0;
        b = 0;

        $display("------------------------------------------------");
        $display("    Starting 16-bit Dadda Multiplier Test");
        $display("------------------------------------------------");

        // Wait 100ns for global reset to finish
        #100;

        // --- Test Case 1: Zero Multiplication ---
        a = 16'd0; b = 16'd0;
        #30;

        // --- Test Case 2: Identity ---
        a = 16'd1; b = 16'd1;
        #30;

        a = 16'd1234; b = 16'd1;
        #30;

        // --- Test Case 3: Small Integers ---
        a = 16'd2; b = 16'd3; // Expect 6
        #30;

        a = 16'd10; b = 16'd15; // Expect 150
        #30;

        // --- Test Case 4: Maximum Values (Corner Case) ---
        a = 16'hFFFF; b = 16'hFFFF; // 65535 * 65535
        #30;

        $finish;
    end

endmodule