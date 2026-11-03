module afifo #(
		parameter	LGFIFO = 3,
		parameter	WIDTH  = 16,
		parameter	NFF    = 2,
		parameter [0:0]	WRITE_ON_POSEDGE = 1'b1,
		parameter [0:0]	OPT_REGISTER_READS = 1'b1
	) (
		input	wire			i_wclk, i_wr_reset_n, i_wr,
		input	wire	[WIDTH-1:0]	i_wr_data,
		output	reg			o_wr_full,
		input	wire			i_rclk, i_rd_reset_n, i_rd,
		output	reg	[WIDTH-1:0]	o_rd_data,
		output	reg			o_rd_empty
	);

	// Internal parameters
	localparam DEPTH = 1 << LGFIFO;
	localparam PTR_W = LGFIFO;
	localparam SYNC_DEPTH = (NFF < 2) ? 2 : NFF;

	// Write domain signals
	reg [WIDTH-1:0] wr_data_reg;
	reg [PTR_W:0]   wr_ptr;
	reg [PTR_W:0]   rd_ptr_wr_sync;
	reg             wr_full_int;
	reg             wr_req;
	reg             wr_ack_wr;
	reg [WIDTH-1:0] wr_data_hold;
	reg             wr_data_valid;

	// Read domain signals
	reg [PTR_W:0]   rd_ptr;
	reg [PTR_W:0]   wr_ptr_rd_sync;
	reg             rd_empty_int;
	reg             rd_ack;
	reg             rd_req_rd;
	reg [WIDTH-1:0] rd_data_sync [0:SYNC_DEPTH-1];
	reg             rd_valid_sync [0:SYNC_DEPTH-1];
	reg [WIDTH-1:0] rd_data_hold;
	reg             rd_data_valid;

	// Synchronizer for write request (wclk -> rclk)
	reg [SYNC_DEPTH-1:0] wr_req_sync;

	// Synchronizer for read acknowledge (rclk -> wclk)
	reg [SYNC_DEPTH-1:0] rd_ack_sync;

	// Synchronizer for read pointer (rclk -> wclk)
	reg [SYNC_DEPTH-1:0][PTR_W:0] rd_ptr_sync;

	// Synchronizer for write pointer (wclk -> rclk)
	reg [SYNC_DEPTH-1:0][PTR_W:0] wr_ptr_sync;

	// Synchronizer for write data valid (wclk -> rclk)
	reg [SYNC_DEPTH-1:0] wr_data_valid_sync;

	// Write clock domain logic
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_ptr <= {(PTR_W+1){1'b0}};
			wr_data_reg <= {WIDTH{1'b0}};
			wr_req <= 1'b0;
			wr_ack_wr <= 1'b0;
			wr_data_hold <= {WIDTH{1'b0}};
			wr_data_valid <= 1'b0;
			o_wr_full <= 1'b0;
		end else begin
			// Synchronize read acknowledge
			rd_ack_sync <= {rd_ack_sync[SYNC_DEPTH-2:0], rd_ack};
			wr_ack_wr <= rd_ack_sync[SYNC_DEPTH-1];

			// Synchronize read pointer
			rd_ptr_sync <= {rd_ptr_sync[SYNC_DEPTH-2:0], rd_ptr};
			rd_ptr_wr_sync <= rd_ptr_sync[SYNC_DEPTH-1];

			// Full condition: write pointer has lapped read pointer by DEPTH
			wr_full_int <= (wr_ptr[PTR_W] != rd_ptr_wr_sync[PTR_W]) && 
						   (wr_ptr[PTR_W-1:0] == rd_ptr_wr_sync[PTR_W-1:0]);
			o_wr_full <= wr_full_int;

			// Write data register
			if (i_wr && !wr_full_int) begin
				wr_data_reg <= i_wr_data;
			end

			// Write request generation
			if (i_wr && !wr_full_int && !wr_req) begin
				wr_req <= 1'b1;
				wr_data_hold <= i_wr_data;
				wr_data_valid <= 1'b1;
			end else if (wr_ack_wr) begin
				wr_req <= 1'b0;
				wr_data_valid <= 1'b0;
				wr_ptr <= wr_ptr + 1'b1;
			end
		end
	end

	// Read clock domain logic
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_ptr <= {(PTR_W+1){1'b0}};
			rd_ack <= 1'b0;
			rd_req_rd <= 1'b0;
			rd_data_hold <= {WIDTH{1'b0}};
			rd_data_valid <= 1'b0;
			o_rd_empty <= 1'b1;
			o_rd_data <= {WIDTH{1'b0}};
			for (int i = 0; i < SYNC_DEPTH; i = i + 1) begin
				rd_data_sync[i] <= {WIDTH{1'b0}};
				rd_valid_sync[i] <= 1'b0;
			end
		end else begin
			// Synchronize write request
			wr_req_sync <= {wr_req_sync[SYNC_DEPTH-2:0], wr_req};

			// Synchronize write pointer
			wr_ptr_sync <= {wr_ptr_sync[SYNC_DEPTH-2:0], wr_ptr};
			wr_ptr_rd_sync <= wr_ptr_sync[SYNC_DEPTH-1];

			// Synchronize write data valid
			wr_data_valid_sync <= {wr_data_valid_sync[SYNC_DEPTH-2:0], wr_data_valid};

			// Empty condition: read pointer equals write pointer
			rd_empty_int <= (rd_ptr == wr_ptr_rd_sync);
			o_rd_empty <= rd_empty_int;

			// Read acknowledge generation
			if (i_rd && !rd_empty_int && !rd_ack) begin
				rd_ack <= 1'b1;
			end else if (wr_req_sync[SYNC_DEPTH-1]) begin
				rd_ack <= 1'b0;
				rd_ptr <= rd_ptr + 1'b1;
			end

			// Data synchronization pipeline
			for (int i = 0; i < SYNC_DEPTH; i = i + 1) begin
				if (i == 0) begin
					rd_data_sync[0] <= wr_data_hold;
					rd_valid_sync[0] <= wr_data_valid_sync[SYNC_DEPTH-1];
				end else begin
					rd_data_sync[i] <= rd_data_sync[i-1];
					rd_valid_sync[i] <= rd_valid_sync[i-1];
				end
			end

			// Output data
			if (OPT_REGISTER_READS) begin
				if (rd_valid_sync[SYNC_DEPTH-1]) begin
					rd_data_hold <= rd_data_sync[SYNC_DEPTH-1];
					rd_data_valid <= 1'b1;
				end else begin
					rd_data_valid <= 1'b0;
				end
				o_rd_data <= rd_data_hold;
			end else begin
				o_rd_data <= rd_data_sync[SYNC_DEPTH-1];
			end
		end
	end

endmodule
