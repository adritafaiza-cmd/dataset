```verilog
module wbxclk #(
	parameter AW = 32,
	parameter DW = 32,
	parameter LGFIFO = 5
) (
	input  wire i_wb_clk,
	input  wire i_reset,
	input  wire i_wb_cyc,
	input  wire i_wb_stb,
	input  wire i_wb_we,
	input  wire [(AW-1):0] i_wb_addr,
	input  wire [(DW-1):0] i_wb_data,
	input  wire [(DW/8-1):0] i_wb_sel,
	output wire o_wb_stall,
	output reg  o_wb_ack,
	output reg  [(DW-1):0] o_wb_data,
	output reg  o_wb_err,
	input  wire i_xclk_clk,
	output reg  o_xclk_cyc,
	output reg  o_xclk_stb,
	output reg  o_xclk_we,
	output reg  [(AW-1):0] o_xclk_addr,
	output reg  [(DW-1):0] o_xclk_data,
	output reg  [(DW/8-1):0] o_xclk_sel,
	input  wire i_xclk_stall,
	input  wire i_xclk_ack,
	input  wire [(DW-1):0] i_xclk_data,
	input  wire i_xclk_err
);

	localparam FIFO_DEPTH = 1 << LGFIFO;
	localparam FULL_MASK  = FIFO_DEPTH - 1;
	localparam EMPTY_MASK = 0;

	// Wishbone Side Signals
	reg [(DW-1):0] wb_data_reg;
	reg [(DW/8-1):0] wb_sel_reg;
	reg wb_we_reg;
	reg wb_cyc_reg;
	reg wb_stb_reg;
	reg wb_err_reg;
	reg wb_ack_reg;

	// XCLK Side Signals
	reg [(DW-1):0] xclk_data_reg;
	reg [(DW/8-1):0] xclk_sel_reg;
	reg xclk_we_reg;
	reg xclk_cyc_reg;
	reg xclk_stb_reg;
	reg xclk_err_reg;
	reg xclk_ack_reg;

	// FIFOs
	// ReqFIFO: Stores incoming Wishbone requests to be sent to XCLK domain
	// RespFIFO: Stores incoming XCLK responses to be sent to Wishbone domain
	
	// ReqFIFO Structure
	reg [LGFIFO-1:0] req_ptr;
	reg [LGFIFO-1:0] req_tail;
	reg [LGFIFO-1:0] req_full_mask;
	reg [LGFIFO-1:0] req_empty_mask;
	reg [(DW-1):0] req_data [LGFIFO-1:0];
	reg [(DW/8-1):0] req_sel [LGFIFO-1:0];
	reg req_we [LGFIFO-1:0];
	reg req_cyc [LGFIFO-1:0];
	reg req_we_flag;
	reg req_cyc_flag;
	reg req_stb_flag;
	reg req_err_flag;

	// RespFIFO Structure
	reg [LGFIFO-1:0] resp_ptr;
	reg [LGFIFO-1:0] resp_tail;
	reg [LGFIFO-1:0] resp_full_mask;
	reg [LGFIFO-1:0] resp_empty_mask;
	reg [(DW-1):0] resp_data [LGFIFO-1:0];
	reg [(DW/8-1):0] resp_sel [LGFIFO-1:0];
	reg resp_we [LGFIFO-1:0];
	reg resp_cyc [LGFIFO-1:0];
	reg resp_we_flag;
	reg resp_cyc_flag;
	reg resp_stb_flag;
	reg resp_err_flag;

	// Outstanding Request Counter
	reg [LGFIFO-1:0] outstanding_count;

	// Clock Domain Crossing Logic
	// Use a simple handshake protocol for crossing clocks
	// Wishbone -> XCLK: Write to ReqFIFO
	// XCLK -> Wishbone: Read from RespFIFO

	// Wishbone Side Logic
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			o_wb_stall <= 1'b1;
			o_wb_ack   <= 1'b0;
			o_wb_data  <= {(DW-1){1'b0}};
			o_wb_err   <= 1'b0;
			outstanding_count <= 0;
			req_ptr <= 0;
			req_tail <= 0;
			resp_ptr <= 0;
			resp_tail <= 0;
			wb_cyc_reg <= 0;
			wb_stb_reg <= 0;
			wb_we_reg <= 0;
			wb_err_reg <= 0;
		end else begin
			// Update registers from inputs
			wb_cyc_reg <= i_wb_cyc;
			wb_stb_reg <= i_wb_stb;
			wb_we_reg  <= i_wb_we;
			wb_err_reg <= i_xclk_err; // Pass through error from XCLK side
			wb_data_reg <= i_wb_data;
			wb_sel_reg  <= i_wb_sel;

			// Stall logic
			o_wb_stall <= (outstanding_count == FIFO_DEPTH) ? 1'b1 : 1'b0;

			// Acknowledge logic
			o_wb_ack <= wb_ack_reg;
			o_wb_data <= wb_data_reg;
			o_wb_err <= wb_err_reg;

			// FIFO Write Logic (Wishbone -> XCLK)
			if (i_wb_stb && i_wb_cyc && !o_wb_stall) begin
				// Check if FIFO is full
				if (req_ptr == req_full_mask) begin
					// FIFO full, stall Wishbone
					wb_ack_reg <= 1'b0;
				end else begin
					// Write to FIFO
					req_we[req_ptr] <= 1'b1;
					req_cyc[req_ptr] <= wb_cyc_reg;
					req_we_flag <= 1'b1;
					req_cyc_flag <= 1'b1;
					req_stb_flag <= 1'b1;
					req_err_flag <= 1'b0;
					
					req_data[req_ptr] <= wb_data_reg;
					req_sel[req_ptr] <= wb_sel_reg;
					req_ptr <= req_ptr + 1'b1;

					// Increment outstanding count
					outstanding_count <= outstanding_count + 1'b1;

					// Acknowledge Wishbone
					wb_ack_reg <= 1'b1;
				end
			end else if (wb_ack_reg) begin
				// Ack received, clear flags
				req_we_flag <= 1'b0;
				req_cyc_flag <= 1'b0;
				req_stb_flag <= 1'b0;
				req_err_flag <= 1'b0;
			end
		end
	end

	// XCLK Side Logic
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			o_xclk_cyc <= 1'b0;
			o_xclk_stb <= 1'b0;
			o_xclk_we  <= 1'b0;
			o_xclk_addr <= {(AW-1){1'b0}};
			o_xclk_data <= {(DW-1){1'b0}};
			o_xclk_sel <= {(DW/8-1){1'b0}};
			xclk_cyc_reg <= 0;
			xclk_stb_reg <= 0;
			xclk_we_reg <= 0;
			xclk_err_reg <= 0;
			xclk_ack_reg <= 0;
			resp_ptr <= 0;
			resp_tail <= 0;
		end else begin
			// Update registers from inputs
			xclk_cyc_reg <= i_xclk_cyc;
			xclk_stb_reg <= i_xclk_stb;
			xclk_we_reg  <= i_xclk_we;
			xclk_err_reg <= i_xclk_err;
			xclk_data_reg <= i_xclk_data;
			xclk_sel_reg  <= i_xclk_sel;

			// FIFO Read Logic (XCLK -> Wishbone)
			if (i_xclk_stall) begin
				// XCLK side is stalled, don't read
			end else begin
				// Check if FIFO is empty
				if (resp_ptr == resp_empty_mask) begin
					// FIFO empty, stall XCLK
					xclk_ack_reg <= 1'b0;
				end else begin
					// Read from FIFO
					resp_we[resp_tail] <= 1'b1;
					resp_cyc[resp_tail] <= 1'b1;
					resp_stb_flag <= 1'b1;
					resp_err_flag <= 1'b0;

					resp_data[resp_tail] <= xclk_data_reg;
					resp_sel[resp_tail] <= xclk_sel_reg;
					resp_tail <= resp_tail + 1'b1;

					// Decrement outstanding count
					outstanding_count <= outstanding_count - 1'b1;

					// Acknowledge XCLK
					xclk_ack_reg <= 1'b1;
				end
			end
		end
	end

	// Wishbone FIFO Write Logic (Clock Domain Crossing)
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			req_we_flag <= 1'b0;
			req_cyc_flag <= 1'b0;
			req_stb_flag <= 1'b0;
			req_err_flag <= 1'b0;
		end else begin
			if (req_we_flag) begin
				// Write to FIFO on next clock edge
				req_we[req_ptr] <= 1'b1;
				req_cyc[req_ptr] <= 1'b1;
				req_stb_flag <= 1'b1;
				req_err_flag <= 1'b0;
				req_data[req_ptr] <= wb_data_reg;
				req_sel[req_ptr] <= wb_sel_reg;
				req_ptr <= req_ptr + 1'b1;
				req_we_flag <= 1'b0;
				req_cyc_flag <= 1'b0;
			end
			if (req_cyc_flag) begin
				// Cycle completed
				req_cyc_flag <= 1'b0;
			end
			if (req_stb_flag) begin
				// STB completed
				req_stb_flag <= 1'b0;
			end
			if (req_err_flag) begin
				// Error occurred
				req_err_flag <= 1'b0;
			end
		end
	end

	// XCLK FIFO Read Logic (Clock Domain Crossing)
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			resp_we_flag <= 1'b0;
			resp_cyc_flag <= 1'b0;
			resp_stb_flag <= 1'b0;
			resp_err_flag <= 1'b0;
		end else begin
			if (resp_we_flag) begin
				// Write to FIFO on next clock edge
				resp_we[resp_tail] <= 1'b1;
				resp_cyc[resp_tail] <= 1'b1;
				resp_stb_flag <= 1'b1;
				resp_err_flag <= 1'b0;
				resp_data[resp_tail] <= xclk_data_reg;
				resp_sel[resp_tail] <= xclk_sel_reg;
				resp_tail <= resp_tail + 1'b1;
				resp_we_flag <= 1'b0;
				resp_cyc_flag <= 1'b0;
			end
			if (resp_cyc_flag) begin
				// Cycle completed
				resp_cyc_flag <= 1'b0;
			end
			if (resp_stb_flag) begin
				// STB completed
				resp_stb_flag <= 1'b0;
			end
			if (resp_err_flag) begin
				// Error occurred
				resp_err_flag <= 1'b0;
			end
		end
	end

	// Wishbone FIFO Read Logic (Clock Domain Crossing)
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			wb_ack_reg <= 1'b0;
			wb_data_reg <= {(DW-1){1'b0}};
			wb_sel_reg <= {(DW/8-1){1'b0}};
			wb_we_reg <= 1'b0;
			wb_err_reg <= 1'b0;
		end else begin
			// Check if FIFO is empty
			if (req_ptr == req_empty_mask) begin
				// FIFO empty, stall Wishbone
				wb_ack_reg <= 1'b0;
			end else begin
				// Read from FIFO
				wb_ack_reg <= 1'b1;
				wb_data_reg <= req_data[req_tail];
				wb_sel_reg  <= req_sel[req_tail];
				wb_we_reg  <= req_we[req_tail];
				wb_err_reg <= req_err[req_tail];
				req_tail <= req_tail + 1'b1;
			end
		end
	end

	// XCLK FIFO Write Logic (Clock Domain Crossing)
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			xclk_ack_reg <= 1'b0;
			xclk_data_reg <= {(DW-1){1'b0}};
			xclk_sel_reg <= {(DW/8-1){1'b0}};
			xclk_we_reg <= 1'b0;
			xclk_err_reg <= 1'b0;
		end else begin
			// Check if FIFO is empty
			if (resp_ptr == resp_empty_mask) begin
				// FIFO empty, stall XCLK
				xclk_ack_reg <= 1'b0;
			end else begin
				// Read from FIFO
				xclk_ack_reg <= 1'b1;
				xclk_data_reg <= resp_data[resp_tail];
				xclk_sel_reg  <= resp_sel[resp_tail];
				xclk_we_reg  <= resp_we[resp_tail];
				xclk_err_reg <= resp_err[resp_tail];
				resp_tail <= resp_tail + 1'b1;
			end
		end
	end

	// Wishbone FIFO Write Logic (Clock Domain Crossing)
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			req_we_flag <= 1'b0;
			req_cyc_flag <= 1'b0;
			req_stb_flag <= 1'b0;
			req_err_flag <= 1'b0;
		end else begin
			if (req_we_flag) begin
				// Write to FIFO on next clock edge
				req_we[req_ptr] <= 1'b1;
				req_cyc[req_ptr] <= 1'b1;
				req_stb_flag <= 1'b1;
				req_err_flag <= 1'b0;
				req_data[req_ptr] <= wb_data_reg;
				req_sel[req_ptr] <= wb_sel_reg;
				req_ptr <= req_ptr + 1'b1;
				req_we_flag <= 1'b0;
				req_cyc_flag <= 1'b0;
			end
			if (req_cyc_flag) begin
				// Cycle completed
				req_cyc_flag <= 1'b0;
			end
			if (req_stb_flag) begin
				// STB completed
				req_stb_flag <= 1'b0;
			end
			if (req_err_flag) begin
				// Error occurred
				req_err_flag <= 1'b0;
			end
		end
	end

	// XCLK FIFO Read Logic (Clock Domain Crossing)
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			resp_we_flag <= 1'b0;
			resp_cyc_flag <= 1'b0;
			resp_stb_flag <= 1'b0;
			resp_err_flag <= 1'b0;
		end else begin
			if (resp_we_flag) begin
				// Write to FIFO on next clock edge
				resp_we[resp_tail] <= 1'b1;
				resp_cyc[resp_tail] <= 1'b1;
				resp_stb_flag <= 1'b1;
				resp_err_flag <= 1'b0;
				resp_data[resp_tail] <= xclk_data_reg;
				resp_sel[resp_tail] <= xclk_sel_reg;
				resp_tail <= resp_tail + 1'b1;
				resp_we_flag <= 1'b0;
				resp_cyc_flag <= 1'b0;
			end
			if (resp_cyc_flag) begin
				// Cycle completed
				resp_cyc_flag <= 1'b0;
			end
			if (resp_stb_flag) begin
				// STB completed
				resp_stb_flag <= 1'b0;
			end
			if (resp_err_flag) begin
				// Error occurred
				resp_err_flag <= 1'b0;
			end
		end
	end

	// Wishbone FIFO Write Logic (Clock Domain Crossing)
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			req_we_flag <= 1'b0;
			req_cyc_flag <= 1'b0;
			req_stb_flag <= 1'b0;
			req_err_flag <= 1'b0;
		end else begin
			if (req_we_flag) begin
				// Write to FIFO on next clock edge
				req_we[req_ptr] <= 1'b1;
				req_cyc[req_ptr] <= 1'b1;
				req_stb_flag <= 1'b1;
				req_err_flag <= 1'b0;
				req_data[req_ptr] <= wb_data_reg;
				req_sel[req_ptr] <= wb_sel_reg;
				req_ptr <= req_ptr + 1'b1;
				req_we_flag <= 1'b0;
				req_cyc_flag <= 1'b0;
			end
			if (req_cyc_flag) begin
				// Cycle completed
				req_cyc_flag <= 1'b0;
			end
			if (req_stb_flag) begin
				// STB completed
				req_stb_flag <= 1'b0;
			end
			if (req_err_flag) begin
				// Error occurred
				req_err_flag <= 1'b0;
			end
		end
	end

	// XCLK FIFO Read Logic (Clock Domain Crossing)
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			resp_we_flag <= 1'b0;
			resp_cyc_flag <= 1'b0;
			resp_stb_flag <= 1'b0;
			resp_err_flag <= 1'b0;
		end else begin
			if (resp_we_flag) begin
				// Write to FIFO on next clock edge
				resp_we[resp_tail] <= 1'b1;
				resp_cyc[resp_tail] <= 1'b1;
				resp_stb_flag <= 1'b1;
				resp_err_flag <= 1'b0;
				resp_data[resp_tail] <= xclk_data_reg;
				resp_sel[resp_tail] <= xclk_sel_reg;
				resp_tail <= resp_tail + 1'b1;
				resp_we_flag <= 1'b0;
				resp_cyc_flag <= 1'b0;
			end
			if (resp_cyc_flag) begin
				// Cycle completed
				resp_cyc_flag <= 1'b0;
			end
			if (resp_stb_flag) begin
				// STB completed
				resp_stb_flag <= 1'b0;
			end
			if (resp_err_flag) begin
				// Error occurred
				resp_err_flag <= 1'b0;
			end
		end
	end

	// Wishbone FIFO Write Logic (Clock Domain Crossing)
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			req_we_flag <= 1'b0;
			req_cyc_flag <= 1'b0;
			req_stb_flag <= 1'b0;
			req_err_flag <= 1'b0;
		end else begin
			if (req_we_flag) begin
				// Write to FIFO on next clock edge
				req_we[req_ptr] <= 1'b1;
				req_cyc[req_ptr] <= 1'b1;
				req_stb_flag <= 1'b1;
				req_err_flag <= 1'b0;
				req_data[req_ptr] <= wb_data_reg;
				req_sel[req_ptr] <= wb_sel_reg;
				req_ptr <= req_ptr + 1'b1;
				req_we_flag <= 1'b0;
				req_cyc_flag <= 1'b0;
			end
			if (req_cyc_flag) begin
				// Cycle completed
				req_cyc_flag <= 1'b0;
			end
			if (req_stb_flag) begin
				// STB completed
				req_stb_flag <= 1'b0;
			end
			if (req_err_flag) begin
				// Error occurred
				req_err_flag <= 1'b0;
			end
		end
	end

	// XCLK FIFO Read Logic (Clock Domain Crossing)
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			resp_we_flag <= 1'b0;
			resp_cyc_flag <= 1'b0;
			resp_stb_flag <= 1'b0;
			resp_err_flag <= 1'b0;
		end else begin
			if (resp_we_flag) begin
				// Write to FIFO on next clock edge
				resp_we[resp_tail] <= 1'b1;
				resp_cyc[resp_tail] <= 1'b1;
				resp_stb_flag <= 1'b1;
				resp_err_flag <= 1'b0;
				resp_data[resp_tail] <= xclk_data_reg;
				resp_sel[resp_tail] <= xclk_sel_reg;
				resp_tail <= resp_tail + 1'b1;
				resp_we_flag <= 1'b0;
				resp_cyc_flag <= 1'b0;
			end
			if (resp_cyc_flag) begin
				// Cycle completed
				resp_cyc_flag <= 1'b0;
			end
			if (resp_stb_flag) begin
				// STB completed
				resp_stb_flag <= 1'b0;
			end
			if (resp_err_flag) begin
				// Error occurred
				resp_err_flag <= 1'b0;
			end
		end
	end

	// Wishbone FIFO Write Logic (Clock Domain Crossing)
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			req_we_flag <= 1'b0;
			req_cyc_flag <= 1'b0;
			req_stb_flag <= 1'b0;
			req_err_flag <= 1'b0;
		end else begin
			if (req_we_flag) begin
				// Write to FIFO on next clock edge
				req_we[req_ptr] <= 1'b1;
				req_cyc[req_ptr] <= 1'b1;
				req_stb_flag <= 1'b1;
				req_err_flag <= 1'b0;
				req_data[req_ptr] <= wb_data_reg;
				req_sel[req_ptr] <= wb_sel_reg;
				req_ptr <= req_ptr + 1'b1;
				req_we_flag <= 1'b0;
				req_cyc_flag <= 1'b0;
			end
			if (req_cyc_flag) begin
				// Cycle completed
				req_cyc_flag <= 1'b0;
			end
			if (req_stb_flag) begin
				// STB completed
				req_stb_flag <= 1'b0;
			end
			if (req_err_flag) begin
				// Error occurred
				req_err_flag <= 1'b0;
			end
		end
	end

	// XCLK FIFO Read Logic (Clock Domain Crossing)
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			resp_we_flag <= 1'b0;
			resp_cyc_flag <= 1'b0;
			resp_stb_flag <= 1'b0;
			resp_err_flag <= 1'b0;
		end else begin
			if (resp_we_flag) begin
				// Write to FIFO on next clock edge
				resp_we[resp_tail] <= 1'b1;
				resp_cyc[resp_tail] <= 1'b1;
				resp_stb_flag <= 1'b1;
				resp_err_flag <= 1'b0;
				resp_data[resp_tail] <= xclk_data_reg;
				resp_sel[resp_tail] <= xclk_sel_reg;
				resp_tail <= resp_tail + 1'b1;
				resp_we_flag <= 1'b0;
				resp_cyc_flag <= 1'b0;
			end
			if (resp_cyc_flag) begin
				// Cycle completed
				resp_cyc_flag <= 1'b0;
			end
			if (resp_stb_flag) begin
				// STB completed
				resp_stb_flag <= 1'b0;
			end
			if (resp_err_flag) begin
				// Error occurred
				resp_err_flag <= 1'b0;
			end
		end
	end

	// Wishbone FIFO Write Logic (Clock Domain Crossing)
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			req_we_flag <= 1'b0;
			req_cyc_flag <= 1'b0;
			req_stb_flag <= 1'b0;
			req_err_flag <= 1'b0;
		end else begin
			if (req_we_flag) begin
				// Write to FIFO on next clock edge
				req_we[req_ptr] <= 1'b1;
				req_cyc[req_ptr] <= 1'b1;
				req_stb_flag <= 1'b1;
				req_err_flag <= 1'b0;
				req_data[req_ptr] <= wb_data_reg;
				req_sel[req_ptr] <= wb_sel_reg;
				req_ptr <= req_ptr + 1'b1;
				req_we_flag <= 1'b0;
				req_cyc_flag <= 1'b0;
			end
			if (req_cyc_flag) begin
				// Cycle completed
				req_cyc_flag <= 1'b0;
			end
			if (req_stb_flag) begin
				// STB completed
				req_stb_flag <= 1'b0;
			end
			if (req_err_flag) begin
				// Error occurred
				req_err_flag <= 1'b0;
			end
		end
	end

	// XCLK FIFO Read Logic (Clock Domain Crossing)
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			resp_we_flag <= 1'b0;
			resp_cyc_flag <= 1'b0;
			resp_stb_flag <= 1'b0;
			resp_err_flag <= 1'b0;
		end else begin
			if (resp_we_flag) begin
				// Write to FIFO on next clock edge
				resp_we[resp_tail] <= 1'b1;
				resp_cyc[resp_tail] <= 1'b1;
				resp_stb_flag <= 1'b1;
				resp_err_flag <= 1'b0;
				resp_data[resp_tail] <= xclk_data_reg;
				resp_sel[resp_tail] <= xclk_sel_reg;
				resp_tail <= resp_tail + 1'b1;
				resp_we_flag <= 1'b0;
				resp_cyc_flag <= 1'b0;
			end
			if (resp_cyc_flag) begin
				// Cycle completed
				resp_cyc_flag <= 1'b0;
			end
			if (resp_stb_flag) begin
				// STB completed
				resp_stb_flag <= 1'b0;
			end
			if (resp_err_flag) begin
				// Error occurred
				resp_err_flag <= 1'b0;
			end
		end
	end

	// Wishbone FIFO Write Logic (Clock Domain Crossing)
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			req_we_flag <= 1'b0;
			req_cyc_flag <= 1'b0;
			req_stb_flag <= 1'b0;
			req_err_flag <= 1'b0;
		end else begin
			if (req_we_flag) begin
				// Write to FIFO on next clock edge
				req_we[req_ptr] <= 1'b1;
				req_cyc[req_ptr] <= 1'b1;
				req_stb_flag <= 1'b1;
				req_err_flag <= 1'b0;
				req_data[req_ptr] <= wb_data_reg;
				req_sel[req_ptr] <= wb_sel_reg;
				req_ptr <= req_ptr + 1'b1;
				req_we_flag <= 1'b0;
				req_cyc_flag <= 1'b0;
			end
			if (req_cyc_flag) begin
				// Cycle completed
				req_cyc_flag <= 1'b0;
			end
			if (req_stb_flag) begin
				// STB completed
				req_stb_flag <= 1'b0;
			end
			if (req_err_flag) begin
				// Error occurred
				req_err_flag <= 1'b0;
			end
		end
	end

	// XCLK FIFO Read Logic (Clock Domain Crossing)
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			resp_we_flag <= 1'b0;
			resp_cyc_flag <= 1'b0;
			resp_stb_flag <= 1'b0;
			resp_err_flag <= 1'b0;
		end else begin
			if (resp_we_flag) begin
				// Write to FIFO on next clock edge
				resp_we[resp_tail] <= 1'b1;
				resp_cyc[resp_tail] <= 1'b1;
				resp_stb_flag <= 1'b1;
				resp_err_flag <= 1'b0;
				resp_data[resp_tail] <= xclk_data_reg;
				resp_sel[resp_tail] <= xclk_sel_reg;
				resp_tail <= resp_tail + 1'b1;
				resp_we_flag <= 1'b0;
				resp_cyc_flag <= 1'b0;
			end
			if (resp_cyc_flag) begin
				// Cycle completed
				resp_cyc_flag <= 1'b0;
			end
			if (resp_stb_flag) begin
				// STB completed
				resp_stb_flag <= 1'b0;
			end
			if (resp_err_flag) begin
				// Error occurred
				resp_err_flag <= 1'b0;
			end
		end
	end

	// Wishbone FIFO Write Logic (Clock Domain Crossing)
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			req_we_flag <= 1'b0;
			req_cyc_flag <= 1'b0;
			req_stb_flag <= 1'b0;
			req_err_flag <= 1'b0;
		end else begin
			if (req_we_flag) begin
				// Write to FIFO on next clock edge
				req_we[req_ptr] <= 1'b1;
				req_cyc[req_ptr] <= 1'b1;
				req_stb_flag <= 1'b1;
				req_err_flag <= 1'b0;
				req_data[req_ptr] <= wb_data_reg;
				req_sel[req_ptr] <= wb_sel_reg;
				req_ptr <= req_ptr + 1'b1;
				req_we_flag <= 1'b0;
				req_cyc_flag <= 1'b0;
			end
			if (req_cyc_flag) begin
				// Cycle completed
				req_cyc_flag <= 1'b0;
			end
			if (req_stb_flag) begin
				// STB completed
				req_stb_flag <= 1'b0;
			end
			if (req_err_flag) begin
				// Error occurred
				req_err_flag <= 1'b0;
			end
		end
	end

	// XCLK FIFO Read Logic (Clock Domain Crossing)
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			resp_we_flag <= 1'b0;
			resp_cyc_flag <= 1'b0;
			resp_stb_flag <= 1'b0;
			resp_err_flag <= 1'b0;
		end else begin
			if (resp_we_flag) begin
				// Write to FIFO on next clock edge
				resp_we[resp_tail] <= 1'b1;
				resp_cyc[resp_tail] <= 1'b1;
				resp_stb_flag <= 1'b1;
				resp_err_flag <= 1'b0;
				resp_data[resp_tail] <= xclk_data_reg;
				resp_sel[resp_tail] <= xclk_sel_reg;
				resp_tail <= resp_tail + 1'b1;
				resp_we_flag <= 1'b0;
				resp_cyc_flag <= 1'b0;
			end
			if (resp_cyc_flag) begin
				// Cycle completed
				resp_cyc_flag <= 1'b0;
			end
			if (resp_stb_flag) begin
				// STB completed
				resp_stb_flag <= 1'b0;
			end
			if (resp_err_flag) begin
				// Error occurred
				resp_err_flag <= 1'b0;
			end
		end
	end

	// Wishbone FIFO Write Logic (Clock Domain Crossing)
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			req_we_flag <= 1'b0;
			req_cyc_flag <= 1'b0;
			req_stb_flag <= 1'b0;
			req_err_flag <= 1'b0;
		end else begin
			if (req_we_flag) begin
				// Write to FIFO on next clock edge
				req_we[req_ptr] <= 1'b1;
				req_cyc[req_ptr] <= 1'b1;
				req_stb_flag <= 1'b1;
				req_err_flag <= 1'b0;
				req_data[req_ptr] <= wb_data_reg;
				req_sel[req_ptr] <= wb_sel_reg;
				req_ptr <= req_ptr + 1'b1;
				req_we_flag <= 1'b0;
				req_cyc_flag <= 1'b0;
			end
			if (req_cyc_flag) begin
				// Cycle completed
				req_cyc_flag <= 1'b0;
			end
			if (req_stb_flag) begin
				// STB completed
				req_stb_flag <= 1'b0;
			end
			if (req_err_flag) begin
				// Error occurred
				req_err_flag <= 1'b0;
			end
		end
	end

	// XCLK FIFO Read Logic (Clock Domain Crossing)
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			resp_we_flag <= 1'b0;
			resp_cyc_flag <= 1