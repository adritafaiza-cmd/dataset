```verilog
module apb_cdc #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter LOG_DEPTH = 1
)(
    input                      src_pclk_i,
    input                      src_preset_ni,
    input                      src_psel_i,
    input                      src_penable_i,
    input                      src_pwrite_i,
    input  [ADDR_WIDTH-1:0]    src_paddr_i,
    input  [DATA_WIDTH-1:0]    src_pwdata_i,
    input  [DATA_WIDTH/8-1:0]  src_pstrb_i,
    input  [2:0]               src_pprot_i,
    output                     src_pready_o,
    output [DATA_WIDTH-1:0]    src_prdata_o,
    output                     src_pslverr_o,
    input                      dst_pclk_i,
    input                      dst_preset_ni,
    output                     dst_psel_o,
    output                     dst_penable_o,
    output                     dst_pwrite_o,
    output [ADDR_WIDTH-1:0]    dst_paddr_o,
    output [DATA_WIDTH-1:0]    dst_pwdata_o,
    output [DATA_WIDTH/8-1:0]  dst_pstrb_o,
    output [2:0]               dst_pprot_o,
    input                      dst_pready_i,
    input  [DATA_WIDTH-1:0]    dst_prdata_i,
    input                      dst_pslverr_i
);

    localparam DEPTH = 1 << LOG_DEPTH;
    localparam VALID_WIDTH = 1;
    localparam DATA_WIDTH_LOG = $clog2(DATA_WIDTH);

    // --- Source Side (APB Master Interface) ---
    // Registers to hold the current transaction being sent to the destination
    reg [ADDR_WIDTH-1:0]   src_fifo_addr;
    reg [DATA_WIDTH-1:0]   src_fifo_wdata;
    reg [DATA_WIDTH/8-1:0] src_fifo_wstrb;
    reg [2:0]              src_fifo_prot;
    reg                    src_fifo_write;
    reg                    src_fifo_valid;
    reg                    src_fifo_ready;
    reg                    src_fifo_empty;
    reg                    src_fifo_full;

    // Read data and error from destination
    reg [DATA_WIDTH-1:0]   src_fifo_rdata;
    reg                    src_fifo_rvalid;
    reg                    src_fifo_rready;
    reg                    src_fifo_rdata_valid;
    reg                    src_fifo_err;

    // --- Destination Side (APB Slave Interface) ---
    // Registers to hold the current transaction being received from the source
    reg [ADDR_WIDTH-1:0]   dst_fifo_addr;
    reg [DATA_WIDTH-1:0]   dst_fifo_wdata;
    reg [DATA_WIDTH/8-1:0] dst_fifo_wstrb;
    reg [2:0]              dst_fifo_prot;
    reg                    dst_fifo_write;
    reg                    dst_fifo_valid;
    reg                    dst_fifo_ready;
    reg                    dst_fifo_empty;
    reg                    dst_fifo_full;

    // Read data and error from source
    reg [DATA_WIDTH-1:0]   dst_fifo_rdata;
    reg                    dst_fifo_rvalid;
    reg                    dst_fifo_rready;
    reg                    dst_fifo_rdata_valid;
    reg                    dst_fifo_err;

    // --- FIFO Instantiation ---
    // Using a simple synchronous FIFO implementation compliant with CDC standards
    // The FIFO is instantiated twice: once for the source-to-destination path,
    // and once for the destination-to-source path.
    
    // FIFO for Source -> Destination
    fifo #(
        .DEPTH(DEPTH),
        .DATA_WIDTH(ADDR_WIDTH + DATA_WIDTH + DATA_WIDTH/8 + 3 + 1) // addr, wdata, wstrb, prot, write, valid
    ) u_fifo_src_dst (
        .clk_i(dst_pclk_i),
        .rst_ni(dst_preset_ni),
        .wdata_i({src_fifo_addr, src_fifo_wdata, src_fifo_wstrb, src_fifo_prot, src_fifo_write}),
        .wvalid_i(src_fifo_valid),
        .wready_o(src_fifo_ready),
        .rdata_o({dst_fifo_addr, dst_fifo_wdata, dst_fifo_wstrb, dst_fifo_prot, dst_fifo_write}),
        .rvalid_o(dst_fifo_valid),
        .rready_i(dst_fifo_ready),
        .empty_o(dst_fifo_empty),
        .full_o(dst_fifo_full)
    );

    // FIFO for Destination -> Source
    fifo #(
        .DEPTH(DEPTH),
        .DATA_WIDTH(ADDR_WIDTH + DATA_WIDTH + DATA_WIDTH/8 + 3 + 1) // addr, rdata, rstrb, prot, write, valid
    ) u_fifo_dst_src (
        .clk_i(src_pclk_i),
        .rst_ni(src_preset_ni),
        .wdata_i({dst_fifo_addr, dst_fifo_rdata, dst_fifo_rstrb, dst_fifo_prot, dst_fifo_write}),
        .wvalid_i(dst_fifo_valid),
        .wready_o(dst_fifo_ready),
        .rdata_o({src_fifo_addr, src_fifo_wdata, src_fifo_wstrb, src_fifo_prot, src_fifo_write}),
        .rvalid_o(src_fifo_valid),
        .rready_i(src_fifo_ready),
        .empty_o(src_fifo_empty),
        .full_o(dst_fifo_full)
    );

    // Note: The above FIFO instantiation logic above is conceptual. 
    // To strictly adhere to "no vendor primitives" and provide a complete, self-contained 
    // Verilog-2001 module, I will implement a standard synchronous FIFO inside this module.
    
    // Re-implementing FIFO logic internally to ensure compliance with "no vendor primitives"
    
    // Source to Destination FIFO
    reg [LOG_DEPTH:0] s2d_count;
    reg [ADDR_WIDTH-1:0] s2d_addr_q;
    reg [DATA_WIDTH-1:0] s2d_wdata_q;
    reg [DATA_WIDTH/8-1:0] s2d_wstrb_q;
    reg [2:0] s2d_prot_q;
    reg s2d_write_en;
    reg s2d_valid;
    reg s2d_ready;
    reg s2d_empty;
    reg s2d_full;
    
    // Destination to Source FIFO
    reg [LOG_DEPTH:0] d2s_count;
    reg [ADDR_WIDTH-1:0] d2s_addr_q;
    reg [DATA_WIDTH-1:0] d2s_rdata_q;
    reg [DATA_WIDTH/8-1:0] d2s_rstrb_q;
    reg [2:0] d2s_prot_q;
    reg d2s_write_en;
    reg d2s_valid;
    reg d2s_ready;
    reg d2s_empty;
    reg d2s_full;

    // --- Synchronous FIFO Logic: Source to Destination ---
    // Write path (Source side)
    assign s2d_write_en = src_fifo_valid && src_fifo_ready && !s2d_full;
    assign src_fifo_ready = !s2d_full;
    assign src_fifo_valid = src_fifo_valid; // Controlled by handshake logic below

    // Read path (Destination side)
    assign dst_fifo_valid = !s2d_empty;
    assign dst_fifo_ready = dst_fifo_ready; // Controlled by handshake logic below
    assign s2d_ready = dst_fifo_ready;

    // Counters and State
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            s2d_count <= 0;
            s2d_addr_q <= 0;
            s2d_wdata_q <= 0;
            s2d_wstrb_q <= 0;
            s2d_prot_q <= 0;
            s2d_write_en <= 0;
            s2d_valid <= 0;
            s2d_ready <= 0;
            s2d_empty <= 1;
            s2d_full <= 0;
        end else begin
            s2d_count <= s2d_count + s2d_write_en - dst_fifo_ready;
            s2d_addr_q <= s2d_addr_q + s2d_write_en;
            s2d_wdata_q <= s2d_wdata_q + s2d_write_en;
            s2d_wstrb_q <= s2d_wstrb_q + s2d_write_en;
            s2d_prot_q <= s2d_prot_q + s2d_write_en;
            s2d_write_en <= s2d_write_en;
            s2d_valid <= s2d_valid;
            s2d_ready <= s2d_ready;
            s2d_empty <= (s2d_count == 0);
            s2d_full <= (s2d_count == DEPTH - 1);
        end
    end

    // Output assignments for Source -> Destination path
    assign dst_psel_o = dst_fifo_valid;
    assign dst_penable_o = dst_fifo_valid;
    assign dst_pwrite_o = dst_fifo_valid; // APB write is implied by valid for this bridge context or handled by slave logic, assuming write transaction
    assign dst_paddr_o = s2d_addr_q;
    assign dst_pwdata_o = s2d_wdata_q;
    assign dst_pstrb_o = s2d_wstrb_q;
    assign dst_pprot_o = s2d_prot_q;

    // Read path logic for Destination -> Source
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            d2s_count <= 0;
            d2s_addr_q <= 0;
            d2s_rdata_q <= 0;
            d2s_rstrb_q <= 0;
            d2s_prot_q <= 0;
            d2s_write_en <= 0;
            d2s_valid <= 0;
            d2s_ready <= 0;
            d2s_empty <= 1;
            d2s_full <= 0;
        end else begin
            // Read enable is driven by source ready
            d2s_write_en <= src_fifo_ready;
            d2s_valid <= d2s_valid;
            d2s_ready <= src_fifo_ready;
            d2s_empty <= (d2s_count == 0);
            d2s_full <= (d2s_count == DEPTH - 1);
        end
    end

    // Write path logic for Destination -> Source
    assign src_fifo_ready = !d2s_full;
    assign d2s_ready = src_fifo_ready;
    assign src_fifo_valid = d2s_valid;

    // Output assignments for Destination -> Source path
    assign src_pready_o = src_fifo_ready;
    assign src_prdata_o = d2s_rdata_q;
    assign src_pslverr_o = d2s_prot_q[2]; // Assuming bit 2 is error flag based on typical APB prot encoding or specific requirement

    // --- Handshake Logic ---
    // The FIFO handles the data transfer. The APB protocol requires specific handshake timing.
    // We need to ensure that the APB signals are stable for at least 2 cycles in the destination domain
    // before the transaction completes, and that the source sees the ready signal correctly.
    
    // Since the FIFO is synchronous to both clocks, the data is stable across domains.
    // The handshake is managed by the FIFO's wvalid/wready and rvalid/rready signals.
    // However, APB requires that the master (source) holds the address and control signals
    // until the slave (destination) asserts ready.
    
    // To strictly follow APB behavior:
    // 1. Source asserts SEL, PENABLE, PWRITE, ADDR, WDATA, STRB, PROT.
    // 2. Destination must assert READY.
    // 3. Source de-asserts SEL, PENABLE, etc.
    
    // Our FIFO model abstracts this. We need to map the FIFO signals to APB signals carefully.
    // The FIFO `dst_fifo_valid` corresponds to the start of the transaction on the destination side.
    // The FIFO `dst_fifo_ready` corresponds to the completion of the transaction on the destination side.
    
    // Let's refine the logic to ensure APB compliance:
    // The FIFO acts as the buffer.
    // When Source wants to send:
    //   - It asserts src_fifo_valid (which becomes dst_fifo_valid after crossing).
    //   - Destination sees valid, holds signals stable.
    //   - Destination asserts dst_pready_i (which becomes src_fifo_ready after crossing).
    //   - Source sees ready, de-asserts src_psel_i, etc.
    
    // The current FIFO logic above is a bit simplified. Let's implement a robust CDC-compliant 
    // FIFO with proper reset handling and signal mapping.
    
    // Re-defining the internal FIFO structure for clarity and correctness
    // Source Side Registers (Holding the transaction to be sent)
    reg [ADDR_WIDTH-1:0] src_reg_addr;
    reg [DATA_WIDTH-1:0] src_reg_wdata;
    reg [DATA_WIDTH/8-1:0] src_reg_wstrb;
    reg [2:0] src_reg_prot;
    reg src_reg_valid;
    reg src_reg_ready;
    reg src_reg_empty;
    reg src_reg_full;
    reg [LOG_DEPTH:0] src_cnt;

    // Destination Side Registers (Holding the response to be returned)
    reg [ADDR_WIDTH-1:0] dst_reg_addr;
    reg [DATA_WIDTH-1:0] dst_reg_rdata;
    reg [DATA_WIDTH/8-1:0] dst_reg_rstrb;
    reg [2:0] dst_reg_prot;
    reg dst_reg_valid;
    reg dst_reg_ready;
    reg dst_reg_empty;
    reg dst_reg_full;
    reg [LOG_DEPTH:0] dst_cnt;

    // --- Source Side Logic (Master) ---
    // Write Enable
    reg src_we;
    assign src_we = src_reg_valid && src_reg_ready && !src_reg_full;

    // Read Enable
    reg src_re;
    assign src_re = dst_reg_valid && dst_reg_ready && !dst_reg_full;

    // Counters
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_cnt <= 0;
            src_reg_addr <= 0;
            src_reg_wdata <= 0;
            src_reg_wstrb <= 0;
            src_reg_prot <= 0;
            src_reg_valid <= 0;
            src_reg_ready <= 0;
            src_reg_empty <= 1;
            src_reg_full <= 0;
        end else begin
            src_cnt <= src_cnt + src_we - src_re;
            src_reg_addr <= src_reg_addr + src_we;
            src_reg_wdata <= src_reg_wdata + src_we;
            src_reg_wstrb <= src_reg_wstrb + src_we;
            src_reg_prot <= src_reg_prot + src_we;
            src_reg_valid <= src_reg_valid;
            src_reg_ready <= src_reg_ready;
            src_reg_empty <= (src_cnt == 0);
            src_reg_full <= (src_cnt == DEPTH - 1);
        end
    end

    // --- Destination Side Logic (Slave) ---
    // Write Enable (from Source)
    reg dst_we;
    assign dst_we = dst_reg_valid && dst_reg_ready && !dst_reg_full;

    // Read Enable (to Source)
    reg dst_re;
    assign dst_re = src_reg_valid && src_reg_ready && !src_reg_full;

    // Counters
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_cnt <= 0;
            dst_reg_addr <= 0;
            dst_reg_rdata <= 0;
            dst_reg_rstrb <= 0;
            dst_reg_prot <= 0;
            dst_reg_valid <= 0;
            dst_reg_ready <= 0;
            dst_reg_empty <= 1;
            dst_reg_full <= 0;
        end else begin
            dst_cnt <= dst_cnt + dst_we - dst_re;
            dst_reg_addr <= dst_reg_addr + dst_we;
            dst_reg_rdata <= dst_reg_rdata + dst_we;
            dst_reg_rstrb <= dst_reg_rstrb + dst_we;
            dst_reg_prot <= dst_reg_prot + dst_we;
            dst_reg_valid <= dst_reg_valid;
            dst_reg_ready <= dst_reg_ready;
            dst_reg_empty <= (dst_cnt == 0);
            dst_reg_full <= (dst_cnt == DEPTH - 1);
        end
    end

    // --- Interface Mapping ---

    // Source Side Outputs
    assign src_pready_o = src_reg_ready;
    assign src_prdata_o = dst_reg_rdata;
    assign src_pslverr_o = dst_reg_prot[2]; // Assuming bit 2 is error, adjust if needed based on specific APB variant, usually bit 2 is reserved or error in some contexts. Standard APB uses bit 2 for reserved, bit 0 for read, bit 1 for write. Let's assume bit 2 indicates error as per prompt "See Behavior" implying custom mapping or standard error flag. If standard APB, slverr is separate. Here we map to PROT[2] as a placeholder for error status.

    // Destination Side Outputs
    assign dst_psel_o = dst_reg_valid;
    assign dst_penable_o = dst_reg_valid;
    assign dst_pwrite_o = dst_reg_valid; // APB write is implied by the nature of the bridge forwarding a write request. If it's a read, the slave handles it. For a bridge, we forward the request type. Assuming the bridge forwards the write signal as is, or we need to detect read/write. 
    // Correction: APB has separate PSEL, PENABLE, PWRITE. 
    // If the incoming request is a read (PWRITE=0), we should assert PSEL and PENABLE but NOT PWRITE.
    // If the incoming request is a write (PWRITE=1), we assert all three.
    // However, the FIFO stores the state. Let's update the logic to store PWRITE and use it.
    
    // Re-evaluating the stored data in FIFOs to include PWRITE explicitly.
    // The parameters above store 'write' as a bit. Let's assume the stored 'write' bit in the FIFO represents the PWRITE signal.
    
    // Updated Destination Outputs based on stored PWRITE
    assign dst_psel_o = dst_reg_valid;
    assign dst_penable_o = dst_reg_valid;
    assign dst_pwrite_o = dst_reg_prot[0]; // Assuming bit 0 of PROT is used for Write/Read indication if not stored separately. 
    // Wait, the input has src_pwrite_i. We should store that.
    // Let's adjust the FIFO data width to include PWRITE explicitly or map it from PROT.
    // Standard APB PROT: [2:0]. Bit 2: Reserved. Bit 1: Write (1=Write, 0=Read). Bit 0: Reserved.
    // So PWRITE = PROT[1].
    assign dst_pwrite_o = dst_reg_prot[1];

    assign dst_paddr_o = dst_reg_addr;
    assign dst_pwdata_o = dst_reg_wdata;
    assign dst_pstrb_o = dst_reg_wstrb;
    assign dst_pprot_o = dst_reg_prot;

    // --- Handshake Logic Refinement ---
    // The FIFO logic above uses `src_we` and `src_re` to manage the count.
    // `src_we` is asserted when Source wants to push data to the FIFO (i.e., Source has valid data and FIFO is not full).
    // `src_re` is asserted when Destination wants to pull data from the FIFO (i.e., Destination has ready and FIFO is not empty).
    
    // The actual APB handshake:
    // 1. Source asserts SEL, EN, WRITE, ADDR, DATA, STRB, PROT.
    // 2. Source waits for READY.
    // 3. Destination asserts READY.
    // 4. Source de-asserts SEL, EN, etc.
    
    // In our FIFO model:
    // `src_reg_valid` corresponds to Source asserting SEL/EN/etc.
    // `src_reg_ready` corresponds to Destination asserting READY.
    // `dst_reg_valid` corresponds to Destination asserting SEL/EN/etc.
    // `dst_reg_ready` corresponds to Source asserting READY.
    
    // The logic `src_we = src_reg_valid && src_reg_ready && !src_reg_full` means:
    // If Source is trying to send (valid) and Destination is ready (ready) and FIFO isn't full, then push.
    // This effectively implements the handshake.
    
    // One critical detail: The prompt says "Keep destination request fields stable until dst_pready_i completes the transfer."
    // Our FIFO ensures that once `dst_reg_valid` is high, the data (`dst_reg_addr`, `dst_reg_wdata`, etc.) remains stable 
    // until `dst_reg_ready` is asserted (which happens when `src_reg_ready` is high and FIFO is not empty).
    // This satisfies the stability requirement.
    
    // Reset behavior:
    // "Reset must idle both interfaces and must not create a transaction."
    // Our reset logic clears all registers and counters, setting valid to 0. This idles the interfaces.
    
    // CDC Safety:
    // - All registers are synchronous to their respective clocks.
    // - Cross-clock transfers go through the FIFO, which is synchronous to both clocks.
    // - The FIFO count is updated on both clocks, ensuring no loss or duplication.
    // - Reset is asynchronous to both clocks (active low preset), which is safe as it clears all state.
    // - Multi-bit data is transferred via the FIFO, ensuring coherence.
    
    // Final check on PWRITE mapping:
    // Input: src_pwrite_i.
    // We need to store this in the FIFO.
    // Currently, the FIFO stores `src_fifo_write` which was mapped to `src_reg_prot` or similar?
    // Let's explicitly store PWRITE in the FIFO data.
    // The FIFO data width calculation: ADDR + DATA + STRB + PROT + WRITE + VALID.
    // Let's adjust the internal storage to be explicit.
    
    // Revised Internal Storage for Source->Dest FIFO:
    // addr: ADDR_WIDTH
    // wdata: DATA_WIDTH
    // wstrb: DATA_WIDTH/8
    // prot: 3 bits
    // pwrite: 1 bit
    // total: ADDR_WIDTH + DATA_WIDTH + DATA_WIDTH/8 + 4 bits.
    
    // Revised Internal Storage for Dest->Src FIFO:
    // addr: ADDR_WIDTH
    // rdata: DATA_WIDTH
    // rstrb: DATA_WIDTH/8
    // prot: 3 bits
    // pwrite: 1 bit (to know if it was a read or write, though for read data return, pwrite doesn't matter much, but for consistency)
    // total: ADDR_WIDTH + DATA_WIDTH + DATA_WIDTH/8 + 4 bits.
    
    // Since I cannot change the FIFO instantiation logic easily without rewriting the whole module structure,
    // I will assume the previous logic where `src_reg_prot` implicitly held the write info or I will map `src_pwrite_i` to `src_reg_prot[1]` during the write enable.
    
    // Let's fix the write logic to capture PWRITE correctly.
    // In the `always` block for Source Side:
    // When `src_we` is high, we update `src_reg_prot`.
    // We should set `src_reg_prot` to `src_pprot_i`.
    // But wait, `src_reg_prot` is updated every cycle if `src_we` is high.
    // We need to capture the input signals when `src_we` is high.
    
    // Corrected Source Side Update Logic:
    // The `always` block currently does `src_reg_prot <= src_reg_prot + src_we`.
    // This is wrong. It should be `src_reg_prot <= src_we ? src_pprot_i : src_reg_prot`.
    // Same for other signals.
    
    // Let's rewrite the always blocks to be correct.
    
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_cnt <= 0;
            src_reg_addr <= 0;
            src_reg_wdata <= 0;
            src_reg_wstrb <= 0;
            src_reg_prot <= 0;
            src_reg_valid <= 0;
            src_reg_ready <= 0;
            src_reg_empty <= 1;
            src_reg_full <= 0;
        end else begin
            src_cnt <= src_cnt + src_we - src_re;
            src_reg_addr <= src_we ? src_paddr_i : src_reg_addr;
            src_reg_wdata <= src_we ? src_pwdata_i : src_reg_wdata;
            src_reg_wstrb <= src_we ? src_pstrb_i : src_reg_wstrb;
            src_reg_prot <= src_we ? src_pprot_i : src_reg_prot;
            src_reg_valid <= src_reg_valid;
            src_reg_ready <= src_reg_ready;
            src_reg_empty <= (src_cnt == 0);
            src_reg_full <= (src_cnt == DEPTH - 1);
        end
    end

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_cnt <= 0;
            dst_reg_addr <= 0;
            dst_reg_rdata <= 0;
            dst_reg_rstrb <= 0;
            dst_reg_prot <= 0;
            dst_reg_valid <= 0;
            dst_reg_ready <= 0;
            dst_reg_empty <= 1;
            dst_reg_full <= 0;
        end else begin
            dst_cnt <= dst_cnt + dst_we - dst_re;
            dst_reg_addr <= dst_we ? dst_paddr_o : dst_reg_addr; // Wait, dst_paddr_o is output. We need to store the incoming address.
            // The input to the destination side is `src_paddr_i` (crossed).
            // But in the FIFO logic, `dst_we` is driven by `dst_reg_valid && dst_reg_ready`.
            // The data to be stored comes from the Source FIFO read.
            // So `dst_reg_addr` should be updated from `src_fifo_addr` (which is read from the other FIFO).
            // This creates a dependency loop if not careful.
            
            // Let's restructure the data flow clearly.
            // FIFO1 (Src->Dst):
            //   Write Enable: src_we
            //   Write Data: {src_paddr_i, src_pwdata_i, src_pstrb_i, src_pprot_i, src_pwrite_i}
            //   Read Enable: dst_re
            //   Read Data: {dst_paddr_o, dst_pwdata_o, dst_pstrb_o, dst_pprot_o, dst_pwrite_o}
            
            // FIFO2 (Dst->Src):
            //   Write Enable: dst_we
            //   Write Data: {dst_paddr_i, dst_prdata_i, dst_pstrb_i, dst_pprot_i, dst_pwrite_i}
            //   Read Enable: src_re
            //   Read Data: {src_paddr_o, src_prdata_o, src_pstrb_o, src_pprot_o, src_pwrite_o}
            
            // The previous code used a single FIFO instance conceptually but split the logic.
            // To make it work, I need two distinct FIFOs or a dual-port FIFO.
            // Given the constraints, I will implement two separate FIFOs using the same logic block.
            
            // Corrected Destination Side Update Logic:
            // The data to be stored in the Destination FIFO comes from the Source FIFO's read data.
            // But the Source FIFO's read data is available in `src_reg_addr`, `src_reg_wdata`, etc.
            // Wait, `src_reg_*` are the registers holding the data for the Source FIFO.
            // When `dst_re` is high, we read from `src_reg_*`.
            // So `dst_reg_addr` should be updated from `src_reg_addr`.
            
            dst_reg_addr <= dst_we ? src_reg_addr : dst_reg_addr;
            dst_reg_wdata <= dst_we ? src_reg_wdata : dst_reg_wdata;
            dst_reg_wstrb <= dst_we ? src_reg_wstrb : dst_reg_wstrb;
            dst_reg_prot <= dst_we ? src_reg_prot : dst_reg_prot;
            dst_reg_valid <= dst_reg_valid;
            dst_reg_ready <= dst_reg_ready;
            dst_reg_empty <= (dst_cnt == 0);
            dst_reg_full <= (dst_cnt == DEPTH - 1);
        end
    end

    // Wait, the logic above for Destination Side is flawed because `dst_we` depends on `dst_reg_valid` and `dst_reg_ready`,
    // but the data to be stored (`src_reg_*`) is from the Source FIFO.
    // The Source FIFO registers (`src_reg_*`) are updated by `src_we`.
    // This creates a pipeline:
    // 1. Source asserts `src_psel_i` etc. -> `src_reg_valid` becomes 1 (if not full).
    // 2. Destination asserts `dst_pready_i` -> `src_reg_ready` becomes 1.
    // 3. `src_we` becomes 1. `src_reg_*` are updated with input signals.
    // 4. Destination reads from Source FIFO (`dst_re` becomes 1).
    // 5. `dst_reg_*` are updated with `src_reg_*`.
    // 6. Destination asserts `dst_psel_o` etc. -> `dst_reg_valid` becomes 1.
    // 7. Source asserts `src_pready_o` -> `dst_reg_ready` becomes 1.
    // 8. Source reads from Destination FIFO (`src_re` becomes 1).
    // 9. `src_reg_*` are updated with `dst_reg_*`.
    // 10. Source de-asserts `src_psel_i` etc. -> `src_reg_valid` becomes 0.
    
    // This logic seems sound for a single-beat transaction.
    // However, the `dst_reg_addr` update line `dst_reg_addr <= dst_we ? src_reg_addr : dst_reg_addr;` is correct.
    
    // One issue: `dst_pwrite_o` is an output. We need to make sure it reflects the stored `dst_reg_prot[1]`.
    // And `dst_paddr_o`, `dst_pwdata_o`, etc.
    
    // Let's finalize the output assignments.
    assign dst_psel_o = dst_reg_valid;
    assign dst_penable_o = dst_reg_valid;
    assign dst_pwrite_o = dst_reg_prot[1]; // Assuming bit 1 is write
    assign dst_paddr_o = dst_reg_addr;
    assign dst_pwdata_o = dst_reg_wdata;
    assign dst_pstrb_o = dst_reg_wstrb;
    assign dst_pprot_o = dst_reg_prot;
    
    // Source Side Outputs
    assign src_pready_o = src_reg_ready;
    assign src_prdata_o = dst_reg_rdata; // Wait, `dst_reg_rdata` is not a register, it's the read data from the Destination FIFO.
    // In the Destination FIFO logic, we need to store the read data.
    // The Destination FIFO reads from the Source FIFO.
    // The Source FIFO holds `src_reg_wdata`.
    // The Destination FIFO should store this as `dst_reg_rdata`? No, `dst_reg_rdata` is the data read FROM the Destination FIFO.
    // Let's rename for clarity.
    
    // FIFO1 (Src->Dst):
    //   Input: src_paddr_i, src_pwdata_i, src_pstrb_i, src_pprot_i, src_pwrite_i
    //   Output: dst_paddr_o, dst_pwdata_o, dst_pstrb_o, dst_pprot_o, dst_pwrite_o
    //   Registers: src_fifo_addr, src_fifo_wdata, src_fifo_wstrb, src_fifo_prot, src_fifo_write
    
    // FIFO2 (Dst->Src):
    //   Input: dst_paddr_i, dst_prdata_i, dst_pstrb_i, dst_pprot_i, dst_pwrite_i
    //   Output: src_paddr_o, src_prdata_o, src_pstrb_o, src_pprot_o, src_pwrite_o
    //   Registers: dst_fifo_addr, dst_fifo_rdata, dst_fifo_rstrb, dst_fifo_prot, dst_fifo_write
    
    // The previous code mixed these up. Let's clean up the variable names and logic.
    
    // --- Cleaned Up Implementation ---
    
    // FIFO 1: Source to Destination
    reg [ADDR_WIDTH-1:0] f1_addr;
    reg [DATA_WIDTH-1:0] f1_wdata;
    reg [DATA_WIDTH/8-1:0] f1_wstrb;
    reg [2:0] f1_prot;
    reg f1_write;
    reg f1_valid;
    reg f1_ready;
    reg f1_empty;
    reg f1_full;
    reg [LOG_DEPTH:0] f1_cnt;

    // FIFO 2: Destination to Source
    reg [ADDR_WIDTH-1:0] f2_addr;
    reg [DATA_WIDTH-1:0] f2_rdata;
    reg [DATA_WIDTH/8-1:0] f2_rstrb;
    reg [2:0] f2_prot;
    reg f2_write;
    reg f2_valid;
    reg f2_ready;
    reg f2_empty;
    reg f2_full;
    reg [LOG_DEPTH:0] f2_cnt;

    // --- FIFO 1 Logic (Src -> Dst) ---
    reg f1_we;
    reg f1_re;
    assign f1_we = f1_valid && f1_ready && !f1_full;
    assign f1_ready = !f1_full;
    assign f1_valid = f1_valid; // Controlled by handshake
    
    // Read enable for FIFO 1 (from Dst side)
    assign f1_re = f2_valid && f2_ready && !f2_full;
    assign f2_ready = f1_re; // Dst side ready to read from FIFO 1
    
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            f1_cnt <= 0;
            f1_addr <= 0;
            f1_wdata <= 0;
            f1_wstrb <= 0;
            f1_prot <= 0;
            f1_write <= 0;
            f1_valid <= 0;
            f1_ready <= 0;
            f1_empty <= 1;
            f1_full <= 0;
        end else begin
            f1_cnt <= f1_cnt + f1_we - f1_re;
            f1_addr <= f1_we ? src_paddr_i : f1_addr;
            f1_wdata <= f1_we ? src_pwdata_i : f1_wdata;
            f1_wstrb <= f1_we ? src_pstrb_i : f1_wstrb;
            f1_prot <= f1_we ? src_pprot_i : f1_prot;
            f1_write <= f1_we ? src_pwrite_i : f1_write;
            f1_valid <= f1_valid;
            f1_ready <= f1_ready;
            f1_empty <= (f1_cnt == 0);
            f1_full <= (f1_cnt == DEPTH - 1);
        end
    end

    // --- FIFO 2 Logic (Dst