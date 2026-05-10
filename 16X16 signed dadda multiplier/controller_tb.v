`timescale 1ns / 1ps

module controller_tb();

    // ---------------------------------------------------------
    // 1. Inputs (reg) and Outputs (wire)
    // ---------------------------------------------------------
    reg clk = 0;
    reg start_stop = 0;
    
    // This 'douta' is an input to the controller, 
    // but in the TB we drive it from our mock memory.
    reg [31:0] douta; 

    wire [3:0] addra;
    wire ena;
    wire [15:0] a;
    wire [15:0] b;

    // ---------------------------------------------------------
    // 2. Clock Generation
    // ---------------------------------------------------------
    always #5 clk = ~clk;

    // ---------------------------------------------------------
    // 3. DUT Instantiation
    // ---------------------------------------------------------
    controller dut (
        .clk(clk),
        .start_stop(start_stop),
        .douta(douta),
        .addra(addra),
        .ena(ena),
        .a(a),
        .b(b)
    );

    // ---------------------------------------------------------
    // 4. BRAM Model
    // ---------------------------------------------------------
    // 32-bit wide memory, depth 16
    reg [31:0] mem [0:15];

    // Initialize Memory with a predictable pattern
    initial begin
        mem[0]= 32'h00400000;
        mem[1]= 32'h1A400000;
        mem[2]= 32'hA132B651;
        mem[3]= 32'h01231234;
        mem[4]= 32'hABCDDEF2;
        mem[5]= 32'h4367AFD1;
        mem[6]= 32'h02135412;
        mem[7]= 32'h34567890;
        mem[8]= 32'h00400000;
        mem[9]= 32'h1A400000;
        mem[10]= 32'hA132B651;
        mem[11]= 32'h01231234;
        mem[12]= 32'hABCDDEF2;
        mem[13]= 32'h4367AFD1;
        mem[14]= 32'h02135412;
        mem[15]= 32'h34567890;
    end

    // Synchronous BRAM read (1-cycle latency logic)
    // This mimics how real BRAM works: Address goes in -> Data comes out next cycle
    always @(posedge clk) begin
        if (ena)
            douta <= mem[addra];
    end

    // ---------------------------------------------------------
    // 5. Stimulus
    // ---------------------------------------------------------
    initial begin
        // Wait 20ns then start
        #20 start_stop = 1;

        // Run for 200ns (enough to wrap around the address counter 0-15-0)
        #200 start_stop = 0;

        // Wait a bit to see it stop
        #50 $finish;
    end

endmodule