`timescale 1ns / 1ps

module tb_design_1;

    reg reset_rtl; 
    reg sys_clock; 
    design_1_wrapper uut (
        .reset_rtl(reset_rtl),
        .sys_clock(sys_clock)
    );

    initial begin
        sys_clock = 0;
        forever #5 sys_clock = ~sys_clock;
    end

    initial begin
        $display("[Time 0] Asserting External Reset (Active High)...");
        reset_rtl = 0; 
        #200;
        $display("[%t] Releasing External Reset...", $time);
        reset_rtl = 1;
        #500; 
        $display("[%t] System should be running now. Waiting for AXI traffic...", $time);
        
        #5000; 

        $display("[%t] Simulation Finished. Check Waveform.", $time);
        $finish;
    end

endmodule