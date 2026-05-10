`timescale 1ns / 1ps

module controller (
    input  wire        m_axi_aclk,
    input  wire        m_axi_aresetn,

    // Debug output
    output reg [31:0]  multiplier_result_debug,

    // AXI4-Lite READ ADDRESS
    output reg [14:0]  m_axi_araddr,
    output reg         m_axi_arvalid,
    input  wire        m_axi_arready,

    // AXI4-Lite READ DATA
    input  wire [31:0] m_axi_rdata,
    input  wire        m_axi_rvalid,
    output reg         m_axi_rready,
    input  wire [1:0]  m_axi_rresp,

    // AXI4-Lite WRITE ADDRESS
    output reg [14:0]  m_axi_awaddr,
    output reg         m_axi_awvalid,
    input  wire        m_axi_awready,

    // AXI4-Lite WRITE DATA
    output reg [31:0]  m_axi_wdata,
    output reg [3:0]   m_axi_wstrb,
    output reg         m_axi_wvalid,
    input  wire        m_axi_wready,

    // AXI4-Lite WRITE RESPONSE
    input  wire        m_axi_bvalid,
    input  wire [1:0]  m_axi_bresp,
    output reg         m_axi_bready
);

    // ============================================================
    // FSM STATES
    // ============================================================
    localparam S_IDLE       = 3'd0;
    localparam S_READ_ADDR  = 3'd1;
    localparam S_READ_DATA  = 3'd2;
    localparam S_CALC       = 3'd3; 
    localparam S_WRITE_TXN  = 3'd4; 
    localparam S_WRITE_RESP = 3'd5;
    localparam S_NEXT_ADDR  = 3'd6;

    reg [2:0] state;

    // Internal tracking for Write Phase
    reg aw_done;
    reg w_done;

    // Registers
    reg [14:0] read_ptr; 
    reg [31:0] data_from_bram;
    wire [31:0] dadda_output;

    // ============================================================
    // DADDA MULTIPLIER
    // ============================================================
    multiplier my_multiplier (
        .a(data_from_bram[31:16]),
        .b(data_from_bram[15:0]),
        .result(dadda_output)
    );

    // ============================================================
    // MAIN AXI MASTER FSM
    // ============================================================
    always @(posedge m_axi_aclk) begin
        if (!m_axi_aresetn) begin
            state <= S_IDLE;
            read_ptr <= 0;
            data_from_bram <= 0;
            multiplier_result_debug <= 0;

            // Reset AXI signals
            m_axi_araddr  <= 0; m_axi_arvalid <= 0;
            m_axi_rready  <= 0;
            m_axi_awaddr  <= 0; m_axi_awvalid <= 0;
            m_axi_wdata   <= 0; m_axi_wvalid  <= 0; m_axi_wstrb <= 0;
            m_axi_bready  <= 0;
            
            aw_done <= 0;
            w_done  <= 0;
        end
        else begin
            case (state)

            // ----------------------------------------------------
            // IDLE / START
            // ----------------------------------------------------
            S_IDLE: begin
                state <= S_READ_ADDR;
            end

            // ----------------------------------------------------
            // READ ADDRESS PHASE 
            // ----------------------------------------------------
            S_READ_ADDR: begin
                m_axi_araddr  <= read_ptr << 2; 
                m_axi_arvalid <= 1'b1;

                // Check VALID here too to be safe, though AR is simpler
                if (m_axi_rvalid) begin
                    m_axi_arvalid <= 1'b0;      
                    state <= S_READ_DATA;
                end
            end

            // ----------------------------------------------------
            // READ DATA PHASE 
            // ----------------------------------------------------
            S_READ_DATA: begin
                m_axi_rready <= 1'b1;           

                if (m_axi_arready) begin
                    data_from_bram <= m_axi_rdata; 
                    m_axi_rready   <= 1'b0;         
                    state <= S_CALC;
                end
            end

            // ----------------------------------------------------
            // CALC PHASE 
            // ----------------------------------------------------
            S_CALC: begin
                multiplier_result_debug <= dadda_output;
                
                // Clear flags for the write phase
                aw_done <= 0; 
                w_done  <= 0;
                
                state <= S_WRITE_TXN;
            end

            // ----------------------------------------------------
            // WRITE TRANSACTION (Address + Data)
            // FIXED: Added checks for (valid && ready)
            // ----------------------------------------------------
            S_WRITE_TXN: begin
                // 1. Handle Write Address
                if (!aw_done) begin
                    m_axi_awaddr  <= read_ptr << 2;
                    m_axi_awvalid <= 1'b1;
                    
                    // FIX: Only clear if we are CURRENTLY valid AND ready
                    if (m_axi_awvalid && m_axi_awready) begin
                        m_axi_awvalid <= 1'b0;
                        aw_done <= 1'b1;
                    end
                end

                // 2. Handle Write Data
                if (!w_done) begin
                    m_axi_wdata  <= dadda_output;
                    m_axi_wstrb  <= 4'b1111;
                    m_axi_wvalid <= 1'b1;

                    // FIX: Only clear if we are CURRENTLY valid AND ready
                    if (m_axi_wvalid && m_axi_wready) begin
                        m_axi_wvalid <= 1'b0;
                        w_done <= 1'b1;
                    end
                end

                // 3. Exit when BOTH are done
                if (aw_done && w_done) begin
                    state <= S_WRITE_RESP;
                end
            end

            // ----------------------------------------------------
            // WRITE RESPONSE 
            // ----------------------------------------------------
            S_WRITE_RESP: begin
                m_axi_bready <= 1'b1;

                if (m_axi_bvalid && m_axi_bready) begin
                    m_axi_bready <= 1'b0;
                    state <= S_NEXT_ADDR;
                end
            end

            // ----------------------------------------------------
            // NEXT ADDR
            // ----------------------------------------------------
            S_NEXT_ADDR: begin
                if (read_ptr < 31) 
                    read_ptr <= read_ptr + 1;
                else 
                    read_ptr <= 0;

                state <= S_READ_ADDR;
            end

            default: state <= S_IDLE;
            endcase
        end
    end

endmodule