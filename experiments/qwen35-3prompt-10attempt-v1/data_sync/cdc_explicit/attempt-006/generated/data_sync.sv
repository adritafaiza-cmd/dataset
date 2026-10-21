```verilog
`timescale 1ns/1ps

module data_sync #(
    parameter STAGES = 2,
    parameter DWIDTH = 8
)(
    input                  clk,
    input                  rstn,
    input  [DWIDTH-1:0]    din,
    input                  dready_i,
    output reg [DWIDTH-1:0] dout,
    output reg             dready_o
);

    // Generate FIFO depth based on STAGES parameter
    // STAGES=2 results in depth 4 (2^2), which is standard for safe crossing
    localparam FIFO_DEPTH = (1 << STAGES);

    // Internal clock domain signals
    wire clk_sync;
    wire rstn_sync;

    // --- Clock and Reset Synchronization ---
    // Use a 2-stage synchronizer for both clock and reset to ensure CDC compliance
    // and safe reset release in the destination domain.
    
    // Clock Synchronizer
    reg clk_sync_1;
    reg clk_sync_2;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            clk_sync_1 <= 1'b0;
            clk_sync_2 <= 1'b0;
        end else begin
            clk_sync_1 <= clk;
            clk_sync_2 <= clk_sync_1;
        end
    end
    assign clk_sync = clk_sync_2;

    // Reset Synchronizer
    // We need to generate an active-high reset for the FIFO logic
    reg rstn_sync_1;
    reg rstn_sync_2;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            rstn_sync_1 <= 1'b0;
            rstn_sync_2 <= 1'b0;
        end else begin
            rstn_sync_1 <= rstn;
            rstn_sync_2 <= rstn_sync_1;
        end
    end
    assign rstn_sync = rstn_sync_2;

    // --- FIFO Implementation ---
    // Using a simple pointer-based FIFO to avoid vendor primitives
    // and ensure structural clarity for CDC tools.
    
    // Pointers
    reg [STAGES-1:0] write_ptr;
    reg [STAGES-1:0] read_ptr;
    reg [STAGES-1:0] next_read_ptr;
    
    // Full/Empty flags
    reg full;
    reg empty;
    
    // Data storage
    reg [DWIDTH-1:0] mem [FIFO_DEPTH-1:0];

    // --- Write Logic (Source Domain) ---
    // Capture data when dready_i is high and FIFO is not full
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            write_ptr <= 0;
            mem      <= 0;
            full     <= 1'b0;
            empty    <= 1'b1;
        end else begin
            if (dready_i && !full) begin
                mem[write_ptr] <= din;
                write_ptr      <= write_ptr + 1'b1;
                // Handle wrap-around for full detection
                if (write_ptr == 0)
                    full <= 1'b1;
                else
                    full <= 0;
            end
            // If full, we do not update write_ptr to prevent overwriting
            // and maintain the full flag.
        end
    end

    // --- Read Logic (Destination Domain) ---
    // Read data when dready_o is asserted (or simply on clock edge if we manage handshake differently)
    // To satisfy "pulse dready_o in clk", we will manage dready_o based on FIFO availability.
    
    // Calculate next read pointer
    always @(posedge clk_sync or negedge rstn_sync) begin
        if (!rstn_sync) begin
            read_ptr <= 0;
            next_read_ptr <= 0;
            empty    <= 1'b1;
        end else begin
            next_read_ptr <= read_ptr + 1'b1;
            if (next_read_ptr == 0)
                empty <= 1'b1;
            else
                empty <= 0;
        end
    end

    // Determine if FIFO is empty based on pointers
    // Empty condition: read_ptr == write_ptr AND we haven't written anything yet?
    // Actually, with the logic above:
    // If write_ptr == read_ptr, it could be empty or full.
    // We track 'empty' explicitly.
    
    // Update read_ptr based on availability
    // We only increment read_ptr if the FIFO is not empty
    always @(posedge clk_sync or negedge rstn_sync) begin
        if (!rstn_sync) begin
            read_ptr <= 0;
        end else begin
            if (!empty) begin
                read_ptr <= next_read_ptr;
            end
        end
    end

    // --- Handshake Control ---
    // dready_o should be high when there is valid data to read
    // This signal is generated in the destination clock domain (clk_sync)
    assign dready_o = !empty;

    // --- Data Output ---
    // dout is assigned in the destination clock domain
    // This ensures no tearing as the value changes only on clk_sync edges
    always @(posedge clk_sync or negedge rstn_sync) begin
        if (!rstn_sync) begin
            dout <= 0;
        end else begin
            if (!empty) begin
                dout <= mem[read_ptr];
            end else begin
                dout <= 0;
            end
        end
    end

endmodule
```<|im_end|>
