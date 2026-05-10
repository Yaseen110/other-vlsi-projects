module controller (
    input  wire        clk,
    input  wire        start_stop,
    input  wire        add_sub,

    input  wire [63:0] douta,

    output reg  [3:0]  addra,
    output reg         ena,

    output reg  [31:0] a,
    output reg  [31:0] b,
    output reg         cin
);

    // FSM states (Verilog style)
    parameter IDLE = 2'b00;
    parameter ADDR = 2'b01;
    parameter DATA = 2'b10;
    parameter DONE = 2'b11;

    reg [1:0] state;

    // Power-up initialization (supported by Xilinx FPGA)
    initial begin
        state = IDLE;
        addra = 4'd0;
        ena   = 1'b0;
        a     = 32'd0;
        b     = 32'd0;
        cin   = 1'b0;
    end

    always @(posedge clk) begin
        case (state)

            IDLE: begin
                ena <= 1'b0;
                if (start_stop) begin
                    addra <= 4'd0;
                    ena   <= 1'b1;
                    state <= ADDR;
                end
            end

            ADDR: begin
                // wait one cycle for BRAM
                state <= DATA;
            end

            DATA: begin
                a   <= douta[63:32];
                b   <= douta[31:0];
                cin <= add_sub;

                if (addra == 4'd15) begin
                    ena   <= 1'b0;
                    state <= DONE;
                end else begin
                    addra <= addra + 1'b1;
                    state <= ADDR;
                end
            end

            DONE: begin
                if (!start_stop)
                    state <= IDLE;
            end

        endcase
    end

endmodule
