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

	localparam DEPTH = 1 << LGFIFO;
	localparam ADDR_WIDTH = LGFIFO;
	localparam PTR_WIDTH = LGFIFO + 1;

	// Write side
	reg [WIDTH-1:0] mem [0:DEPTH-1];
	reg [PTR_WIDTH-1:0] wr_ptr;
	reg [PTR_WIDTH-1:0] rd_ptr_wr;
	reg [PTR_WIDTH-1:0] rd_ptr_wr_sync1;
	reg [PTR_WIDTH-1:0] rd_ptr_wr_sync2;
	reg [PTR_WIDTH-1:0] rd_ptr_wr_sync3;
	reg [PTR_WIDTH-1:0] rd_ptr_wr_sync4;
	reg [PTR_WIDTH-1:0] rd_ptr_wr_sync5;
	reg [PTR_WIDTH-1:0] rd_ptr_wr_sync6;
	reg [PTR_WIDTH-1:0] rd_ptr_wr_sync7;
	reg [PTR_WIDTH-1:0] rd_ptr_wr_sync8;

	// Read side
	reg [PTR_WIDTH-1:0] rd_ptr;
	reg [PTR_WIDTH-1:0] wr_ptr_rd;
	reg [PTR_WIDTH-1:0] wr_ptr_rd_sync1;
	reg [PTR_WIDTH-1:0] wr_ptr_rd_sync2;
	reg [PTR_WIDTH-1:0] wr_ptr_rd_sync3;
	reg [PTR_WIDTH-1:0] wr_ptr_rd_sync4;
	reg [PTR_WIDTH-1:0] wr_ptr_rd_sync5;
	reg [PTR_WIDTH-1:0] wr_ptr_rd_sync6;
	reg [PTR_WIDTH-1:0] wr_ptr_rd_sync7;
	reg [PTR_WIDTH-1:0] wr_ptr_rd_sync8;

	// Read data register
	reg [WIDTH-1:0] rd_data_reg;
	reg [WIDTH-1:0] rd_data_reg_next;

	// Write clock domain
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_ptr <= {PTR_WIDTH{1'b0}};
			rd_ptr_wr_sync1 <= {PTR_WIDTH{1'b0}};
			rd_ptr_wr_sync2 <= {PTR_WIDTH{1'b0}};
			rd_ptr_wr_sync3 <= {PTR_WIDTH{1'b0}};
			rd_ptr_wr_sync4 <= {PTR_WIDTH{1'b0}};
			rd_ptr_wr_sync5 <= {PTR_WIDTH{1'b0}};
			rd_ptr_wr_sync6 <= {PTR_WIDTH{1'b0}};
			rd_ptr_wr_sync7 <= {PTR_WIDTH{1'b0}};
			rd_ptr_wr_sync8 <= {PTR_WIDTH{1'b0}};
			o_wr_full <= 1'b0;
		end else begin
			rd_ptr_wr_sync1 <= rd_ptr_wr;
			rd_ptr_wr_sync2 <= rd_ptr_wr_sync1;
			rd_ptr_wr_sync3 <= rd_ptr_wr_sync2;
			rd_ptr_wr_sync4 <= rd_ptr_wr_sync3;
			rd_ptr_wr_sync5 <= rd_ptr_wr_sync4;
			rd_ptr_wr_sync6 <= rd_ptr_wr_sync5;
			rd_ptr_wr_sync7 <= rd_ptr_wr_sync6;
			rd_ptr_wr_sync8 <= rd_ptr_wr_sync7;

			if (i_wr && !o_wr_full) begin
				mem[wr_ptr[ADDR_WIDTH-1:0]] <= i_wr_data;
				wr_ptr <= wr_ptr + 1'b1;
			end

			// Full condition: write pointer has lapped read pointer by DEPTH
			// wr_ptr[MSB] != rd_ptr_wr_sync8[MSB] && wr_ptr[ADDR_WIDTH-1:0] == rd_ptr_wr_sync8[ADDR_WIDTH-1:0]
			o_wr_full <= (wr_ptr[PTR_WIDTH-1] != rd_ptr_wr_sync8[PTR_WIDTH-1]) &&
						 (wr_ptr[ADDR_WIDTH-1:0] == rd_ptr_wr_sync8[ADDR_WIDTH-1:0]);
		end
	end

	// Read clock domain
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_ptr <= {PTR_WIDTH{1'b0}};
			wr_ptr_rd_sync1 <= {PTR_WIDTH{1'b0}};
			wr_ptr_rd_sync2 <= {PTR_WIDTH{1'b0}};
			wr_ptr_rd_sync3 <= {PTR_WIDTH{1'b0}};
			wr_ptr_rd_sync4 <= {PTR_WIDTH{1'b0}};
			wr_ptr_rd_sync5 <= {PTR_WIDTH{1'b0}};
			wr_ptr_rd_sync6 <= {PTR_WIDTH{1'b0}};
			wr_ptr_rd_sync7 <= {PTR_WIDTH{1'b0}};
			wr_ptr_rd_sync8 <= {PTR_WIDTH{1'b0}};
			o_rd_empty <= 1'b1;
			o_rd_data <= {WIDTH{1'b0}};
			rd_data_reg <= {WIDTH{1'b0}};
		end else begin
			wr_ptr_rd_sync1 <= wr_ptr_rd;
			wr_ptr_rd_sync2 <= wr_ptr_rd_sync1;
			wr_ptr_rd_sync3 <= wr_ptr_rd_sync2;
			wr_ptr_rd_sync4 <= wr_ptr_rd_sync3;
			wr_ptr_rd_sync5 <= wr_ptr_rd_sync4;
			wr_ptr_rd_sync6 <= wr_ptr_rd_sync5;
			wr_ptr_rd_sync7 <= wr_ptr_rd_sync6;
			wr_ptr_rd_sync8 <= wr_ptr_rd_sync7;

			// Empty condition: read pointer equals write pointer
			o_rd_empty <= (rd_ptr == wr_ptr_rd_sync8);

			if (i_rd && !o_rd_empty) begin
				rd_ptr <= rd_ptr + 1'b1;
			end

			// Read data: present the word at the current read pointer
			// When OPT_REGISTER_READS is 1, register the output
			if (OPT_REGISTER_READS) begin
				rd_data_reg <= mem[rd_ptr[ADDR_WIDTH-1:0]];
				o_rd_data <= rd_data_reg;
			end else begin
				o_rd_data <= mem[rd_ptr[ADDR_WIDTH-1:0]];
			end
		end
	end

	// Synchronize write pointer to read domain
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			wr_ptr_rd <= {PTR_WIDTH{1'b0}};
		end else begin
			wr_ptr_rd <= wr_ptr;
		end
	end

	// Synchronize read pointer to write domain
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			rd_ptr_wr <= {PTR_WIDTH{1'b0}};
		end else begin
			rd_ptr_wr <= rd_ptr;
		end
	end

endmodule
