module apbxclk #(
	parameter	C_APB_ADDR_WIDTH = 12,
	parameter	C_APB_DATA_WIDTH = 32,
	parameter [0:0]	OPT_REGISTERED = 1'b0,
	localparam	AW = C_APB_ADDR_WIDTH,
	localparam	DW = C_APB_DATA_WIDTH
) (
	input	wire			S_APB_PCLK, S_PRESETn,
	input	wire			S_APB_PSEL,
	input	wire			S_APB_PENABLE,
	output	reg			S_APB_PREADY,
	input	wire	[AW-1:0]	S_APB_PADDR,
	input	wire			S_APB_PWRITE,
	input	wire	[DW-1:0]	S_APB_PWDATA,
	input	wire	[DW/8-1:0]	S_APB_PWSTRB,
	input	wire	[2:0]		S_APB_PPROT,
	output	wire	[DW-1:0]	S_APB_PRDATA,
	output	wire			S_APB_PSLVERR,
	input	wire			M_APB_PCLK,
	output	reg			M_PRESETn,
	output	reg			M_APB_PSEL,
	output	reg			M_APB_PENABLE,
	input	wire			M_APB_PREADY,
	output	wire	[AW-1:0]	M_APB_PADDR,
	output	wire			M_APB_PWRITE,
	output	wire	[DW-1:0]	M_APB_PWDATA,
	output	wire	[DW/8-1:0]	M_APB_PWSTRB,
	output	wire	[2:0]		M_APB_PPROT,
	input	wire	[DW-1:0]	M_APB_PRDATA,
	input	wire			M_APB_PSLVERR
);

    // Internal signals
    reg [AW-1:0] m_addr_reg;
    reg          m_write_reg;
    reg [DW-1:0] m_wdata_reg;
    reg [DW/8-1:0] m_wstrb_reg;
    reg [2:0]    m_pprot_reg;

    reg          m_req_valid;
    reg          m_req_valid_sync1;
    reg          m_req_valid_sync2;
    reg          m_req_valid_sync3;
    reg          m_req_valid_sync4;

    reg          m_done_valid;
    reg          m_done_valid_sync1;
    reg          m_done_valid_sync2;
    reg          m_done_valid_sync3;
    reg          m_done_valid_sync4;

    reg          s_req_pending;
    reg          s_done_pending;

    reg [DW-1:0] s_rdata_reg;
    reg          s_pslverr_reg;

    // Reset synchronizer for M domain
    reg [3:0] m_reset_sync;

    // M domain reset
    always @(posedge M_APB_PCLK or negedge m_reset_sync[3]) begin
        if (!m_reset_sync[3]) begin
            m_reset_sync <= 4'b0000;
        end else begin
            m_reset_sync <= {m_reset_sync[2:0], 1'b1};
        end
    end

    assign M_PRESETn = m_reset_sync[3];

    // M domain: request valid synchronizer
    always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
        if (!M_PRESETn) begin
            m_req_valid_sync1 <= 1'b0;
            m_req_valid_sync2 <= 1'b0;
            m_req_valid_sync3 <= 1'b0;
            m_req_valid_sync4 <= 1'b0;
        end else begin
            m_req_valid_sync1 <= m_req_valid;
            m_req_valid_sync2 <= m_req_valid_sync1;
            m_req_valid_sync3 <= m_req_valid_sync2;
            m_req_valid_sync4 <= m_req_valid_sync3;
        end
    end

    // M domain: done valid synchronizer
    always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
        if (!M_PRESETn) begin
            m_done_valid_sync1 <= 1'b0;
            m_done_valid_sync2 <= 1'b0;
            m_done_valid_sync3 <= 1'b0;
            m_done_valid_sync4 <= 1'b0;
        end else begin
            m_done_valid_sync1 <= m_done_valid;
            m_done_valid_sync2 <= m_done_valid_sync1;
            m_done_valid_sync3 <= m_done_valid_sync2;
            m_done_valid_sync4 <= m_done_valid_sync3;
        end
    end

    // M domain: APB master state machine
    reg m_sel_reg;
    reg m_enable_reg;

    always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
        if (!M_PRESETn) begin
            m_sel_reg    <= 1'b0;
            m_enable_reg <= 1'b0;
            m_done_valid <= 1'b0;
        end else begin
            if (m_req_valid_sync4 && !m_sel_reg && !m_enable_reg) begin
                // Setup phase
                m_sel_reg    <= 1'b1;
                m_enable_reg <= 1'b0;
                m_done_valid <= 1'b0;
            end else if (m_sel_reg && !m_enable_reg) begin
                // Access phase
                m_sel_reg    <= 1'b1;
                m_enable_reg <= 1'b1;
                m_done_valid <= 1'b0;
            end else if (m_sel_reg && m_enable_reg) begin
                if (M_APB_PREADY) begin
                    // Transfer complete
                    m_sel_reg    <= 1'b0;
                    m_enable_reg <= 1'b0;
                    m_done_valid <= 1'b1;
                end else begin
                    // Wait
                    m_sel_reg    <= 1'b1;
                    m_enable_reg <= 1'b1;
                    m_done_valid <= 1'b0;
                end
            end else begin
                // Idle
                m_sel_reg    <= 1'b0;
                m_enable_reg <= 1'b0;
                m_done_valid <= 1'b0;
            end
        end
    end

    assign M_APB_PSEL    = m_sel_reg;
    assign M_APB_PENABLE = m_enable_reg;

    // M domain: capture request data when request is accepted
    always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
        if (!M_PRESETn) begin
            m_addr_reg  <= {AW{1'b0}};
            m_write_reg <= 1'b0;
            m_wdata_reg <= {DW{1'b0}};
            m_wstrb_reg <= {(DW/8){1'b0}};
            m_pprot_reg <= 3'b000;
        end else if (m_req_valid_sync4 && !m_sel_reg && !m_enable_reg) begin
            m_addr_reg  <= S_APB_PADDR;
            m_write_reg <= S_APB_PWRITE;
            m_wdata_reg <= S_APB_PWDATA;
            m_wstrb_reg <= S_APB_PWSTRB;
            m_pprot_reg <= S_APB_PPROT;
        end
    end

    assign M_APB_PADDR  = m_addr_reg;
    assign M_APB_PWRITE = m_write_reg;
    assign M_APB_PWDATA = m_wdata_reg;
    assign M_APB_PWSTRB = m_wstrb_reg;
    assign M_APB_PPROT  = m_pprot_reg;

    // S domain: done valid synchronizer
    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            m_done_valid_sync1 <= 1'b0;
            m_done_valid_sync2 <= 1'b0;
            m_done_valid_sync3 <= 1'b0;
            m_done_valid_sync4 <= 1'b0;
        end else begin
            m_done_valid_sync1 <= m_done_valid;
            m_done_valid_sync2 <= m_done_valid_sync1;
            m_done_valid_sync3 <= m_done_valid_sync2;
            m_done_valid_sync4 <= m_done_valid_sync3;
        end
    end

    // S domain: capture response data when done is received
    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            s_rdata_reg   <= {DW{1'b0}};
            s_pslverr_reg <= 1'b0;
        end else if (m_done_valid_sync4) begin
            s_rdata_reg   <= M_APB_PRDATA;
            s_pslverr_reg <= M_APB_PSLVERR;
        end
    end

    assign S_APB_PRDATA  = s_rdata_reg;
    assign S_APB_PSLVERR = s_pslverr_reg;

    // S domain: request valid generation
    // A request is valid when S_APB_PSEL is asserted and we are not already pending
    wire s_req_valid = S_APB_PSEL && !s_req_pending;

    // S domain: request valid synchronizer to M domain
    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            m_req_valid <= 1'b0;
            s_req_pending <= 1'b0;
        end else begin
            if (s_req_valid) begin
                m_req_valid <= 1'b1;
                s_req_pending <= 1'b1;
            end else if (m_done_valid_sync4) begin
                m_req_valid <= 1'b0;
                s_req_pending <= 1'b0;
            end else begin
                m_req_valid <= 1'b0;
            end
        end
    end

    // S domain: PREADY generation
    // PREADY is asserted when the corresponding downstream transaction has completed
    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            S_APB_PREADY <= 1'b0;
        end else begin
            if (m_done_valid_sync4) begin
                S_APB_PREADY <= 1'b1;
            end else begin
                S_APB_PREADY <= 1'b0;
            end
        end
    end

endmodule
