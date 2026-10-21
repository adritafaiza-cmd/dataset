```verilog
module wbxclk #(
	parameter	AW=32,
				DW=32,
				LGFIFO = 5
) (
	input	wire			i_wb_clk, i_reset,
	input	wire			i_wb_cyc, i_wb_stb, i_wb_we,
	input	wire	[(AW-1):0]	i_wb_addr,
	input	wire	[(DW-1):0]	i_wb_data,
	input	wire	[(DW/8-1):0]	i_wb_sel,
	output	wire			o_wb_stall,
	output	reg			o_wb_ack,
	output	reg	[(DW-1):0]	o_wb_data,
	output	reg			o_wb_err,
	input	wire			i_xclk_clk,
	output	reg			o_xclk_cyc,
	output	reg			o_xclk_stb,
	output	reg			o_xclk_we,
	output	reg	[(AW-1):0]	o_xclk_addr,
	output	reg	[(DW-1):0]	o_xclk_data,
	output	reg	[(DW/8-1):0]	o_xclk_sel,
	input	wire			i_xclk_stall,
	input	wire			i_xclk_ack,
	input	wire	[(DW-1):0]	i_xclk_data,
	input	wire			i_xclk_err
);

	// ------------------------------------------------------------------
	// CDC Strategy:
	// 1. Handshake Protocol: Use a 2-phase handshake (Req/Ack) to cross
	//    the clock domains. This ensures no metastability issues for single-bit
	//    control signals.
	// 2. FIFO for Data: Since data is multi-bit and must remain coherent,
	//    a synchronous FIFO is used to store data from the WB domain until
	//    it can be safely read by the XCLK domain.
	// 3. Reset Synchronization: The global reset is synchronized in both
	//    domains to ensure safe state initialization.
	// ------------------------------------------------------------------

	// Synchronized Reset Signals
	reg [1:0] i_reset_sync_wb;
	reg [1:0] i_reset_sync_xclk;

	// ------------------------------------------------------------------
	// WB Domain Logic
	// ------------------------------------------------------------------
	// Synchronize Reset
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset)
			i_reset_sync_wb <= 2'b00;
		else begin
			i_reset_sync_wb[0] <= i_reset;
			i_reset_sync_wb[1] <= i_reset_sync_wb[0];
		end
	end

	// Detect valid WB cycle (Cyc & Stb)
	reg [1:0] wb_cycle_valid;
	always @(posedge i_wb_clk) begin
		if (i_reset)
			wb_cycle_valid <= 2'b00;
		else
			wb_cycle_valid <= {wb_cycle_valid[0], i_wb_cyc & i_wb_stb};
	end

	// Detect WB Ack (to know when to stop holding data)
	// We need to detect the rising edge of Ack to know the cycle is done.
	// However, for a simple FIFO bridge, we usually just wait for the FIFO
	// to be full or the destination to be ready.
	// Here, we will use a pointer-based approach where we push to FIFO on
	// valid cycle and pull from FIFO on valid XCLK cycle.
	// The "Ack" in WB domain is generated when the FIFO is not full.

	reg [1:0] wb_ack_sync;
	always @(posedge i_wb_clk) begin
		if (i_reset)
			wb_ack_sync <= 2'b00;
		else
			wb_ack_sync <= {wb_ack_sync[0], i_xclk_ack}; // Note: i_xclk_ack is async, need sync
	end

	// Synchronize XCLK Ack into WB domain
	reg [1:0] xclk_ack_sync_wb;
	always @(posedge i_wb_clk) begin
		if (i_reset)
			xclk_ack_sync_wb <= 2'b00;
		else
			xclk_ack_sync_wb <= {xclk_ack_sync_wb[0], i_xclk_ack};
	end

	// Determine if we can accept a new WB cycle
	// We can accept if:
	// 1. WB Cycle is valid (Cyc & Stb)
	// 2. FIFO is not full
	// 3. Global reset is not active
	reg wb_can_accept;
	always @(posedge i_wb_clk) begin
		if (i_reset)
			wb_can_accept <= 1'b0;
		else
			wb_can_accept <= (wb_cycle_valid[1] && 
			                   !xclk_ack_sync_wb[1] && // If XCLK acked, we can potentially push next
			                   (2**LGFIFO - wb_fifo_wptr) > 1'b1); // Simplified check: not full
	end

	// Actually, the standard handshake is:
	// WB Master sends Cyc/Stb.
	// Slave (this module) checks if it can accept.
	// If yes, it asserts Ack.
	// If no, it asserts Stall.
	// The FIFO depth determines the latency.
	
	// Let's refine the logic:
	// We need to track the number of outstanding requests.
	// Outstanding = (FIFO Full) OR (FIFO has data waiting to be read by XCLK but XCLK is stalled).
	// Actually, simpler: 
	// If FIFO is full, we must stall WB.
	// If FIFO is not full, we can accept, BUT we must ensure the XCLK side is ready to read eventually.
	// Since it's a FIFO, the XCLK side will drain it. The only constraint is FIFO Full.
	// Exception: If XCLK is stalled, the FIFO fills up. Once full, WB must stall.
	
	// Synchronize XCLK Stall into WB domain
	reg [1:0] xclk_stall_sync_wb;
	always @(posedge i_wb_clk) begin
		if (i_reset)
			xclk_stall_sync_wb <= 2'b00;
		else
			xclk_stall_sync_wb <= {xclk_stall_sync_wb[0], i_xclk_stall};
	end

	// Logic to generate WB Ack and Stall
	// We can accept a new beat if:
	// 1. Current WB cycle is valid.
	// 2. FIFO is not full.
	// 3. (Optional but good practice) We don't want to push if the FIFO is empty and we just pushed? 
	//    No, FIFO handles that.
	// The critical path is FIFO Full.
	
	reg wb_ack_gen;
	reg wb_stall_gen;

	always @(posedge i_wb_clk) begin
		if (i_reset) begin
			wb_ack_gen <= 1'b0;
			wb_stall_gen <= 1'b1;
		end else begin
			// Check if we can accept
			if (wb_cycle_valid[1] && 
			    (2**LGFIFO - wb_fifo_wptr) > 1'b1 && 
			    !xclk_stall_sync_wb[1]) begin
				// We can accept.
				// Note: Even if XCLK is stalled, as long as FIFO isn't full, we can accept.
				// The FIFO will buffer the data.
				wb_ack_gen <= 1'b1;
				wb_stall_gen <= 1'b0;
			end else begin
				wb_ack_gen <= 1'b0;
				wb_stall_gen <= 1'b1;
			end
		end
	end

	// ------------------------------------------------------------------
	// FIFO Implementation (WB Domain Write, XCLK Domain Read)
	// ------------------------------------------------------------------
	// We need a FIFO that stores {Addr, Data, Sel, We}
	// Depth = 2^LGFIFO
	// Write Enable: wb_ack_gen (when valid cycle detected and space available)
	// Read Enable: Controlled by XCLK domain logic (when XCLK cycle valid and FIFO not empty)

	// FIFO Parameters
	localparam FIFO_DEPTH = 1 << LGFIFO;
	localparam FIFO_ADDR_WIDTH = LGFIFO;

	// FIFO Signals
	reg [AW-1:0] fifo_addr_in;
	reg [DW-1:0] fifo_data_in;
	reg [(DW/8)-1:0] fifo_sel_in;
	reg fifo_we_in;

	reg [AW-1:0] fifo_addr_out;
	reg [DW-1:0] fifo_data_out;
	reg [(DW/8)-1:0] fifo_sel_out;
	reg fifo_re_out;

	reg [FIFO_ADDR_WIDTH-1:0] wb_fifo_wptr;
	reg [FIFO_ADDR_WIDTH-1:0] wb_fifo_rptr;
	reg [FIFO_ADDR_WIDTH-1:0] wb_fifo_full;
	reg [FIFO_ADDR_WIDTH-1:0] wb_fifo_empty;

	// Write Pointer Logic (WB Domain)
	always @(posedge i_wb_clk) begin
		if (i_reset)
			wb_fifo_wptr <= 1'b0;
		else if (wb_ack_gen)
			wb_fifo_wptr <= wb_fifo_wptr + 1'b1;
	end

	// Read Pointer Logic (XCLK Domain)
	// We need to synchronize the read enable from XCLK domain to the FIFO pointer logic?
	// No, the FIFO pointer logic for reading is in the XCLK domain.
	// The WB domain only writes. The XCLK domain only reads.
	// We need to synchronize the "Read Enable" signal from XCLK to the FIFO internal logic?
	// Standard dual-port FIFO or single-port with sync?
	// Let's use a single-port FIFO where Write is WB domain, Read is XCLK domain.
	// We need to sync the Read Enable signal from XCLK to the WB domain to update the read pointer?
	// No, the read pointer is updated in the XCLK domain.
	// The WB domain needs to know if the FIFO is empty to generate Stall?
	// Actually, Stall is generated by "FIFO Full". Empty is not needed for Stall logic 
	// unless we want to optimize, but "Full" is the hard limit.
	// However, we need to know if the FIFO is empty to stop reading? No, the XCLK logic controls reading.
	// But we need to synchronize the "Read Enable" signal across domains to update the read pointer safely.
	// We will use a pointer synchronization mechanism.

	// Let's implement a simple pointer sync.
	// WB Domain: Writes to FIFO.
	// XCLK Domain: Reads from FIFO.
	// We need to sync the Read Pointer from XCLK to WB to check Empty status? 
	// Actually, for Stall, we only need Full.
	// But for the XCLK side to know when to stop reading (to avoid over-reading), it needs Empty.
	// So we need to sync the Read Pointer from XCLK to WB to generate the Empty signal for XCLK?
	// Or sync the Write Pointer from WB to XCLK to generate Full signal for XCLK?
	// Standard approach:
	// 1. Sync Write Pointer (WB -> XCLK) to generate Full signal in XCLK.
	// 2. Sync Read Pointer (XCLK -> WB) to generate Empty signal in WB (optional, but good for flow control).
	// 3. Sync Read Enable (XCLK -> WB) to update Read Pointer in WB? No, Read Pointer is updated in XCLK.
	//    We need to sync the Read Enable signal to the WB domain to update the Read Pointer?
	//    No, the Read Pointer is updated in the XCLK domain.
	//    The WB domain needs to know if the FIFO is empty to prevent underflow? 
	//    No, the FIFO is single port.
	//    Let's stick to:
	//    - WB Domain: Generates Write Enable. Maintains Write Pointer.
	//    - XCLK Domain: Generates Read Enable. Maintains Read Pointer.
	//    - Cross Domain: 
	//      a. Sync Write Pointer (WB -> XCLK) to detect Full in XCLK.
	//      b. Sync Read Pointer (XCLK -> WB) to detect Empty in WB (for Stall logic if needed, but Full is primary).
	//      c. Sync Read Enable (XCLK -> WB) to update Read Pointer in WB? No.
	//      d. Sync Write Enable (WB -> XCLK) to update Write Pointer in XCLK? No.
	//      
	//    Actually, the simplest robust way for a FIFO crossing:
	//    1. Write Pointer (WB) -> Sync to XCLK -> Used to generate Full signal in XCLK.
	//    2. Read Pointer (XCLK) -> Sync to WB -> Used to generate Empty signal in WB.
	//    3. Write Enable (WB) -> Sync to XCLK -> Used to update Write Pointer in XCLK? No, Write Pointer is in WB.
	//       Wait, if Write Pointer is in WB, how does XCLK know when to stop writing?
	//       XCLK doesn't write. WB writes.
	//       So WB needs to know if FIFO is Full.
	//       Full is detected by comparing Write Pointer and Read Pointer.
	//       Since Read Pointer is in XCLK, we must sync Read Pointer to WB to detect Full.
	//       Similarly, XCLK needs to know if FIFO is Empty to stop reading.
	//       Empty is detected by comparing Read Pointer and Write Pointer.
	//       Since Write Pointer is in WB, we must sync Write Pointer to XCLK to detect Empty.
	//
	//    So:
	//    - WB Domain: Has Write Pointer. Receives Synced Read Pointer (from XCLK).
	//      Calculates Full = (WPtr == RPtr + 1) (or similar).
	//      Calculates Empty = (WPtr == RPtr).
	//      Generates Write Enable based on WB Cycle and !Full.
	//    - XCLK Domain: Has Read Pointer. Receives Synced Write Pointer (from WB).
	//      Calculates Empty = (RPtr == WPtr).
	//      Calculates Full = (RPtr == WPtr - 1).
	//      Generates Read Enable based on XCLK Cycle and !Empty.
	//
	//    This requires syncing both pointers.

	// Synchronize Read Pointer (XCLK -> WB)
	reg [FIFO_ADDR_WIDTH-1:0] xclk_rptr_sync_wb;
	always @(posedge i_xclk_clk) begin
		if (i_reset)
			xclk_rptr_sync_wb <= 1'b0;
		else
			xclk_rptr_sync_wb <= xclk_fifo_rptr;
	end

	// Synchronize Write Pointer (WB -> XCLK)
	reg [FIFO_ADDR_WIDTH-1:0] wb_wptr_sync_xclk;
	always @(posedge i_wb_clk) begin
		if (i_reset)
			wb_wptr_sync_xclk <= 1'b0;
		else
			wb_wptr_sync_xclk <= wb_fifo_wptr;
	end

	// FIFO State in WB Domain
	// We need to store the data.
	// Since we are using a single module, we can instantiate a generic FIFO or write the logic.
	// Given the constraints, let's write the logic explicitly.
	// We need a memory array.
	reg [DW-1:0] fifo_mem_data [0:2**LGFIFO-1];
	reg [(DW/8)-1:0] fifo_mem_sel [0:2**LGFIFO-1];
	reg fifo_mem_we [0:2**LGFIFO-1];

	// Write Logic in WB Domain
	always @(posedge i_wb_clk) begin
		if (i_reset) begin
			fifo_mem_we <= 1'b0;
		end else if (wb_ack_gen) begin
			fifo_mem_we[wb_fifo_wptr] <= 1'b1;
		end else begin
			fifo_mem_we <= 1'b0;
		end
	end

	// Read Logic in XCLK Domain
	// We need to generate Read Enable in XCLK domain.
	// Read Enable = (XCLK Cycle Valid) AND (!Empty)
	// Empty = (xclk_fifo_rptr == wb_wptr_sync_xclk)
	
	reg xclk_fifo_re;
	always @(posedge i_xclk_clk) begin
		if (i_reset)
			xclk_fifo_re <= 1'b0;
		else begin
			// Check Empty
			reg empty_flag;
			if (xclk_fifo_rptr == wb_wptr_sync_xclk)
				empty_flag <= 1'b1;
			else
				empty_flag <= 1'b0;
			
			if (i_xclk_cyc & i_xclk_stb & !empty_flag)
				xclk_fifo_re <= 1'b1;
			else
				xclk_fifo_re <= 1'b0;
		end
	end

	// Update Read Pointer in XCLK Domain
	always @(posedge i_xclk_clk) begin
		if (i_reset)
			xclk_fifo_rptr <= 1'b0;
		else if (xclk_fifo_re)
			xclk_fifo_rptr <= xclk_fifo_rptr + 1'b1;
	end

	// Update Write Pointer in WB Domain (already done above)
	// But we need to ensure the pointers are consistent.
	// The write pointer logic was:
	// if (wb_ack_gen) wb_fifo_wptr <= wb_fifo_wptr + 1;
	// wb_ack_gen is 1 if (wb_cycle_valid && !Full).
	// Full = (wb_fifo_wptr == xclk_rptr_sync_wb) ? No, Full is usually (WPtr == RPtr + 1) for circular buffer.
	// Let's define Full condition properly.
	// If WPtr == RPtr, FIFO is empty.
	// If WPtr == (RPtr + 1) mod Depth, FIFO is full.
	
	// Re-evaluating WB Ack Logic with proper Full check
	// We need to sync Read Pointer to WB to check Full.
	// Full = (wb_fifo_wptr == (xclk_rptr_sync_wb + 1) % Depth)
	
	reg wb_full_flag;
	always @(posedge i_wb_clk) begin
		if (i_reset)
			wb_full_flag <= 1'b0;
		else begin
			if (wb_fifo_wptr == (xclk_rptr_sync_wb + 1) % 2**LGFIFO)
				wb_full_flag <= 1'b1;
			else
				wb_full_flag <= 1'b0;
		end
	end

	// Re-generate wb_ack_gen and wb_stall_gen with correct Full logic
	always @(posedge i_wb_clk) begin
		if (i_reset) begin
			wb_ack_gen <= 1'b0;
			wb_stall_gen <= 1'b1;
		end else begin
			if (wb_cycle_valid[1] && !wb_full_flag && !xclk_stall_sync_wb[1]) begin
				wb_ack_gen <= 1'b1;
				wb_stall_gen <= 1'b0;
			end else begin
				wb_ack_gen <= 1'b0;
				wb_stall_gen <= 1'b1;
			end
		end
	end

	// Data Output in WB Domain
	// o_wb_data should be the data from the FIFO at the current Read Pointer?
	// No, the FIFO is used to buffer the data.
	// The WB Master expects data on the ACK cycle.
	// So, when WB sends a cycle, we push data to FIFO.
	// When WB receives ACK, it expects data to be valid on the next cycle?
	// Or does it expect data on the same cycle?
	// Standard Wishbone: Data is valid on the same cycle as Ack.
	// But we are crossing domains.
	// If we push data to FIFO on the WB cycle, and the FIFO is empty before that,
	// then on the ACK cycle, we can read from the FIFO.
	// So, o_wb_data should be the data at the Read Pointer.
	// But wait, if we push data on the WB cycle, and the Read Pointer hasn't moved yet,
	// then the data at Read Pointer is old data (from previous cycle).
	// This is a problem.
	// Solution: The FIFO must be deep enough to hold the data until the ACK is received.
	// But the ACK is received in the XCLK domain.
	// The WB domain needs to know when to output data.
	// Actually, the standard behavior for a bridge is:
	// 1. WB Master sends Cyc/Stb/Addr/Data.
	// 2. Bridge asserts Ack.
	// 3. WB Master expects Data on the same cycle as Ack.
	// So, the Bridge must have the data ready in the WB domain on the Ack cycle.
	// This means the data must be available in the WB domain before the Ack is asserted.
	// But the data comes from the XCLK domain? No, the data is from WB Master (i_wb_data).
	// So the Bridge just forwards i_wb_data to o_wb_data?
	// Yes! The data path from WB Master to WB Master (via the bridge) is synchronous to WB clock.
	// The bridge just needs to forward the data.
	// The FIFO is only needed for the control signals (Cyc/Stb/Ack) and Address?
	// No, the Address is also needed.
	// But the data is just passed through.
	// Wait, the requirement says: "Forward each accepted cycle exactly once to the o_xclk_* ports."
	// And "Return ack/err/data to the source."
	// So, the data returned to the source (WB Master) is the data from the XCLK slave?
	// No, the ports are:
	// Input: i_wb_data (from WB Master)
	// Output: o_wb_data (to WB Master)
	// Input: i_xclk_data (from XCLK Slave)
	// Output: o_xclk_data (to XCLK Slave)
	//
	// So, the bridge has two data paths:
	// 1. WB Master -> XCLK Slave (Write): i_wb_data -> o_xclk_data
	// 2. XCLK Slave -> WB Master (Read): i_xclk_data -> o_wb_data
	//
	// Path 1 (Write):
	// WB Master sends Data. Bridge forwards it to XCLK Slave.
	// This requires buffering if XCLK is slower or stalled.
	// So we need a FIFO for Write Data.
	//
	// Path 2 (Read):
	// XCLK Slave sends Data. Bridge forwards it to WB Master.
	// This requires buffering if WB is slower or stalled.
	// So we need a FIFO for Read Data.
	//
	// So we need TWO FIFOs:
	// 1. Write FIFO: Stores {Addr, Data, Sel, We} from WB to XCLK.
	// 2. Read FIFO: Stores {Data, Err} from XCLK to WB.
	//
	// Let's restructure.
	//
	// Write FIFO (WB -> XCLK):
	// - Write Enable: wb_ack_gen (when WB cycle valid and FIFO not full)
	// - Write Data: {i_wb_addr, i_wb_data, i_wb_sel, i_wb_we}
	// - Read Enable: Controlled by XCLK domain (when XCLK cycle valid and FIFO not empty)
	//
	// Read FIFO (XCLK -> WB):
	// - Write Enable: Controlled by XCLK domain (when XCLK cycle valid and FIFO not full)
	// - Write Data: {i_xclk_data, i_xclk_err}
	// - Read Enable: Controlled by WB domain (when WB cycle valid and FIFO not empty)
	//
	// This is a classic dual-FIFO bridge.
	
	// ------------------------------------------------------------------
	// Write FIFO (WB -> XCLK)
	// ------------------------------------------------------------------
	localparam WRITE_FIFO_DEPTH = 1 << LGFIFO;
	localparam WRITE_FIFO_ADDR_WIDTH = LGFIFO;
	
	reg [AW-1:0] w_fifo_addr [0:WRITE_FIFO_DEPTH-1];
	reg [DW-1:0] w_fifo_data [0:WRITE_FIFO_DEPTH-1];
	reg [(DW/8)-1:0] w_fifo_sel [0:WRITE_FIFO_DEPTH-1];
	reg w_fifo_we [0:WRITE_FIFO_DEPTH-1];
	
	reg [WRITE_FIFO_ADDR_WIDTH-1:0] w_fifo_wptr;
	reg [WRITE_FIFO_ADDR_WIDTH-1:0] w_fifo_rptr;
	reg [WRITE_FIFO_ADDR_WIDTH-1:0] w_fifo_full;
	reg [WRITE_FIFO_ADDR_WIDTH-1:0] w_fifo_empty;

	// Sync Read Pointer (XCLK -> WB) for Write FIFO
	reg [WRITE_FIFO_ADDR_WIDTH-1:0] xclk_rptr_sync_wb_w;
	always @(posedge i_xclk_clk) begin
		if (i_reset)
			xclk_rptr_sync_wb_w <= 1'b0;
		else
			xclk_rptr_sync_wb_w <= w_fifo_rptr;
	end

	// Sync Write Pointer (WB -> XCLK) for Write FIFO
	reg [WRITE_FIFO_ADDR_WIDTH-1:0] wb_wptr_sync_xclk_w;
	always @(posedge i_wb_clk) begin
		if (i_reset)
			wb_wptr_sync_xclk_w <= 1'b0;
		else
			wb_wptr_sync_xclk_w <= w_fifo_wptr;
	end

	// Write Logic (WB Domain)
	always @(posedge i_wb_clk) begin
		if (i_reset) begin
			w_fifo_we <= 1'b0;
		end else if (wb_ack_gen) begin
			w_fifo_we[w_fifo_wptr] <= 1'b1;
		end else begin
			w_fifo_we <= 1'b0;
		end
	end

	// Read Logic (XCLK Domain)
	// Read Enable = (XCLK Cycle Valid) AND (!Empty)
	// Empty = (w_fifo_rptr == wb_wptr_sync_xclk_w)
	reg w_fifo_re;
	always @(posedge i_xclk_clk) begin
		if (i_reset)
			w_fifo_re <= 1'b0;
		else begin
			reg empty_flag_w;
			if (w_fifo_rptr == wb_wptr_sync_xclk_w)
				empty_flag_w <= 1'b1;
			else
				empty_flag_w <= 1'b0;
			
			if (i_xclk_cyc & i_xclk_stb & !empty_flag_w)
				w_fifo_re <= 1'b1;
			else
				w_fifo_re <= 1'b0;
		end
	end

	// Update Pointers (Write FIFO)
	always @(posedge i_wb_clk) begin
		if (i_reset)
			w_fifo_wptr <= 1'b0;
		else if (wb_ack_gen)
			w_fifo_wptr <= w_fifo_wptr + 1'b1;
	end

	always @(posedge i_xclk_clk) begin
		if (i_reset)
			w_fifo_rptr <= 1'b0;
		else if (w_fifo_re)
			w_fifo_rptr <= w_fifo_rptr + 1'b1;
	end

	// Full/Empty Logic (Write FIFO)
	// Full = (w_fifo_wptr == (w_fifo_rptr + 1) % Depth)
	// Empty = (w_fifo_wptr == w_fifo_rptr)
	// We need these signals in both domains.
	
	// In WB Domain:
	reg w_fifo_full_wb;
	always @(posedge i_wb_clk) begin
		if (i_reset)
			w_fifo_full_wb <= 1'b0;
		else begin
			if (w_fifo_wptr == (w_fifo_rptr + 1) % WRITE_FIFO_DEPTH)
				w_fifo_full_wb <= 1'b1;
			else
				w_fifo_full_wb <= 1'b0;
		end
	end

	// In XCLK Domain:
	reg w_fifo_empty_xclk;
	always @(posedge i_xclk_clk) begin
		if (i_reset)
			w_fifo_empty_xclk <= 1'b0;
		else begin
			if (w_fifo_rptr == wb_wptr_sync_xclk_w)
				w_fifo_empty_xclk <= 1'b1;
			else
				w_fifo_empty_xclk <= 1'b0;
		end
	end

	// ------------------------------------------------------------------
	// Read FIFO (XCLK -> WB)
	// ------------------------------------------------------------------
	localparam READ_FIFO_DEPTH = 1 << LGFIFO;
	localparam READ_FIFO_ADDR_WIDTH = LGFIFO;
	
	reg [DW-1:0] r_fifo_data [0:READ_FIFO_DEPTH-1];
	reg r_fifo_err [0:READ_FIFO_DEPTH-1];
	reg r_fifo_we [0:READ_FIFO_DEPTH-1];
	
	reg [READ_FIFO_ADDR_WIDTH-1:0] r_fifo_wptr;
	reg [READ_FIFO_ADDR_WIDTH-1:0] r_fifo_rptr;
	reg [READ_FIFO_ADDR_WIDTH-1:0] r_fifo_full;
	reg [READ_FIFO_ADDR_WIDTH-1:0] r_fifo_empty;

	// Sync Read Pointer (WB -> XCLK) for Read FIFO
	reg [READ_FIFO_ADDR_WIDTH-1:0] wb_rptr_sync_xclk_r;
	always @(posedge i_wb_clk) begin
		if (i_reset)
			wb_rptr_sync_xclk_r <= 1'b0;
		else
			wb_rptr_sync_xclk_r <= r_fifo_rptr;
	end

	// Sync Write Pointer (XCLK -> WB) for Read FIFO
	reg [READ_FIFO_ADDR_WIDTH-1:0] xclk_wptr_sync_wb_r;
	always @(posedge i_xclk_clk) begin
		if (i_reset)
			xclk_wptr_sync_wb_r <= 1'b0;
		else
			xclk_wptr_sync_wb_r <= r_fifo_wptr;
	end

	// Write Logic (XCLK Domain)
	// Write Enable = (XCLK Cycle Valid) AND (!Full)
	// Full = (r_fifo_wptr == (r_fifo_rptr + 1) % Depth)
	// We need Full signal in XCLK domain.
	reg r_fifo_full_xclk;
	always @(posedge i_xclk_clk) begin
		if (i_reset)
			r_fifo_full_xclk <= 1'b0;
		else begin
			if (r_fifo_wptr == (r_fifo_rptr + 1) % READ_FIFO_DEPTH)
				r_fifo_full_xclk <= 1'b1;
			else
				r_fifo_full_xclk <= 1'b0;
		end
	end

	always @(posedge i_xclk_clk) begin
		if (i_reset)
			r_fifo_we <= 1'b0;
		else if (i_xclk_cyc & i_xclk_stb & !r_fifo_full_xclk) begin
			r_fifo_we[r_fifo_wptr] <= 1'b1;
		end else begin
			r_fifo_we <= 1'b0;
		end
	end

	// Read Logic (WB Domain)
	// Read Enable = (WB Cycle Valid) AND (!Empty)
	// Empty = (r_fifo_rptr == xclk_wptr_sync_wb_r)
	reg r_fifo_re;
	always @(posedge i_wb_clk) begin
		if (i_reset)
			r_fifo_re <= 1'b0;
		else begin
			reg empty_flag_r;
			if (r_fifo_rptr == xclk_wptr_sync_wb_r)
				empty_flag_r <= 1'b1;
			else
				empty_flag_r <= 1'b0;
			
			if (wb_cycle_valid[1] & !empty_flag_r)
				r_fifo_re <= 1'b1;
			else
				r_fifo_re <= 1'b0;
		end
	end

	// Update Pointers (Read FIFO)
	always @(posedge i_xclk_clk) begin
		if (i_reset)
			r_fifo_wptr <= 1'b0;
		else if (r_fifo_we[r_fifo_wptr])
			r_fifo_wptr <= r_fifo_wptr + 1'b1;
	end

	always @(posedge i_wb_clk) begin
		if (i_reset)
			r_fifo_rptr <= 1'b0;
		else if (r_fifo_re)
			r_fifo_rptr <= r_fifo_rptr + 1'b1;
	end

	// Full/Empty Logic (Read FIFO)
	// In WB Domain:
	reg r_fifo_empty_wb;
	always @(posedge i_wb_clk) begin
		if (i_reset)
			r_fifo_empty_wb <= 1'b0;
		else begin
			if (r_fifo_rptr == xclk_wptr_sync_wb_r)
				r_fifo_empty_wb <= 1'b1;
			else
				r_fifo_empty_wb <= 1'b0;
		end
	end

	// In XCLK Domain:
	reg r_fifo_full_xclk; // Already defined above, but let's use it for Write Enable
	// We already used r_fifo_full_xclk for Write Enable.

	// ------------------------------------------------------------------
	// Output Generation
	// ------------------------------------------------------------------

	// WB Outputs
	o_wb_stall = wb_stall_gen;
	o_wb_ack = wb_ack_gen;
	o_wb_err = r_fifo_data[r_fifo_rptr]; // Data from Read FIFO
	o_wb_data = r_fifo_data[r_fifo_rptr]; // Same as err? No, err is separate.
	// Wait, o_wb_data and o_wb_err are separate outputs.
	// o_wb_data should be the data payload.
	// o_wb_err should be the error flag.
	// The Read FIFO stores {Data, Err}.
	// Let's adjust the Read FIFO storage.
	// Actually, the Read FIFO stores the data from XCLK.
	// The XCLK slave sends Data and Err.
	// So the Read FIFO should store Data and Err separately or combined.
	// Let's store them separately for clarity.
	// But the pointer logic is the same.
	// So, o_wb_data = r_fifo_data[r_fifo_rptr];
	// o_wb_err = r_fifo_err[r_fifo_rptr];

	// XCLK Outputs
	o_xclk_cyc = w_fifo_re; // Reuse w_fifo_re? No, w_fifo_re is for reading from Write FIFO.
	// We need to generate XCLK Cyc/Stb/We/Addr/Sel based on the Write FIFO read.
	// When w_fifo_re is high, we output the data from the Write FIFO.
	// But we need to ensure the XCLK cycle is valid.
	// The XCLK slave expects a cycle.
	// So, o_xclk_cyc = w_fifo_re;
	// o_xclk_stb = w_fifo_re;
	// o_xclk_we = w_fifo_sel[w_fifo_rptr]; // Wait, w_fifo_sel is in the Write FIFO.
	// We need to output the data from the Write FIFO when w_fifo_re is high.
	// But w_fifo_re is generated in XCLK domain.
	// So we can use it directly.
	
	// Let's refine the XCLK output logic.
	// When w_fifo_re is high, we output the contents of the Write FIFO at w_fifo_rptr.
	// But w_fifo_rptr is in XCLK domain.
	// So we can access w_fifo_addr[w_fifo_rptr], etc.
	
	// However, we need to ensure that the XCLK cycle is only asserted when the FIFO has data.
	// w_fifo_re is already gated by !Empty.
	// So, o_xclk_cyc = w_fifo_re;
	// o_xclk_stb = w_fifo_re;
	// o_xclk_we = w_fifo