module apbxclk #(
        parameter   C_APB_ADDR_WIDTH = 12,
        parameter   C_APB_DATA_WIDTH = 32,
        parameter [0:0]   OPT_REGISTERED = 1'b0,
        localparam  AW = C_APB_ADDR_WIDTH,
        localparam  DW = C_APB_DATA_WIDTH
    ) (
        input   wire            S_APB_PCLK, S_PRESETn,
        input   wire            S_APB_PSEL,
        input   wire            S_APB_PENABLE,
        output  reg             S_APB_PREADY,
        input   wire    [AW-1:0]  S_APB_PADDR,
        input   wire            S_APB_PWRITE,
        input   wire    [DW-1:0]  S_APB_PWDATA,
        input   wire    [DW/8-1:0] S_APB_PWSTRB,
        input   wire    [2:0]   S_APB_PPROT,
        output  wire    [DW-1:0]  S_APB_PRDATA,
        output  wire            S_APB_PSLVERR,
        input   wire            M_APB_PCLK,
        output  reg             M_PRESETn,
        output  reg             M_APB_PSEL,
        output  reg             M_APB_PENABLE,
        input   wire            M_APB_PREADY,
        output  wire    [AW-1:0]  M_APB_PADDR,
        output  wire            M_APB_PWRITE,
        output  wire    [DW-1:0]  M_APB_PWDATA,
        output  wire    [DW/8-1:0] M_APB_PWSTRB,
        output  wire    [2:0]   M_APB_PPROT,
        input   wire    [DW-1:0]  M_APB_PRDATA,
        input   wire            M_APB_PSLVERR
    );

    // Internal signals for S_APB side
    reg [AW-1:0] s_req_addr_ff1, s_req_addr_ff2;
    reg          s_req_write_ff1, s_req_write_ff2;
    reg [DW-1:0] s_req_wdata_ff1, s_req_wdata_ff2;
    reg [DW/8-1:0] s_req_wstrb_ff1, s_req_wstrb_ff2;
    reg [2:0]  s_req_prot_ff1, s_req_prot_ff2;
    reg          s_req_valid_ff1, s_req_valid_ff2;

    // Internal signals for M_APB side
    reg [AW-1:0] m_req_addr_ff1, m_req_addr_ff2;
    reg          m_req_write_ff1, m_req_write_ff2;
    reg [DW-1:0] m_req_wdata_ff1, m_req_wdata_ff2;
    reg [DW/8-1:0] m_req_wstrb_ff1, m_req_wstrb_ff2;
    reg [2:0]  m_req_prot_ff1, m_req_prot_ff2;
    reg          m_req_valid_ff1, m_req_valid_ff2;
    reg [DW-1:0] m_resp_rdata_ff1, m_resp_rdata_ff2;
    reg          m_resp_slverr_ff1, m_resp_slverr_ff2;

    // S_APB side logic
    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            S_APB_PREADY <= 0;
            s_req_valid_ff1 <= 0;
        end else begin
            S_APB_PREADY <= m_req_ready_ff2;

            if (S_APB_PSEL && S_APB_PENABLE && !s_req_valid_ff1) begin
                s_req_addr_ff1 <= S_APB_PADDR;
                s_req_write_ff1 <= S_APB_PWRITE;
                s_req_wdata_ff1 <= S_APB_PWDATA;
                s_req_wstrb_ff1 <= S_APB_PWSTRB;
                s_req_prot_ff1 <= S_APB_PPROT;
                s_req_valid_ff1 <= 1;
            end else if (m_req_ready_ff2) begin
                s_req_valid_ff1 <= 0;
            end
        end
    end

    // First stage of two-stage flop-flop for S_APB to M_APB
    always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            s_req_addr_ff2 <= 0;
            s_req_write_ff2 <= 0;
            s_req_wdata_ff2 <= 0;
            s_req_wstrb_ff2 <= 0;
            s_req_prot_ff2 <= 0;
            s_req_valid_ff2 <= 0;
        end else begin
            s_req_addr_ff2 <= s_req_addr_ff1;
            s_req_write_ff2 <= s_req_write_ff1;
            s_req_wdata_ff2 <= s_req_wdata_ff1;
            s_req_wstrb_ff2 <= s_req_wstrb_ff1;
            s_req_prot_ff2 <= s_req_prot_ff1;
            s_req_valid_ff2 <= s_req_valid_ff1;
        end
    end

    // Second stage of two-stage flop-flop for S_APB to M_APB
    always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            m_req_addr_ff1 <= 0;
            m_req_write_ff1 <= 0;
            m_req_wdata_ff1 <= 0;
            m_req_wstrb_ff1 <= 0;
            m_req_prot_ff1 <= 0;
            m_req_valid_ff1 <= 0;
        end else begin
            m_req_addr_ff1 <= s_req_addr_ff2;
            m_req_write_ff1 <= s_req_write_ff2;
            m_req_wdata_ff1 <= s_req_wdata_ff2;
            m_req_wstrb_ff1 <= s_req_wstrb_ff2;
            m_req_prot_ff1 <= s_req_prot_ff2;
            m_req_valid_ff1 <= s_req_valid_ff2;
        end
    end

    // Drive M_APB side signals
    always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            M_PRESETn <= 0;
            M_APB_PSEL <= 0;
            M_APB_PENABLE <= 0;
        end else begin
            M_PRESETn <= 1;
            M_APB_PSEL <= m_req_valid_ff1;
            M_APB_PENABLE <= m_req_valid_ff1;
        end
    end

    // First stage of two-stage flop-flop for M_APB to S_APB
    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            m_req_addr_ff2 <= 0;
            m_req_write_ff2 <= 0;
            m_req_wdata_ff2 <= 0;
            m_req_wstrb_ff2 <= 0;
            m_req_prot_ff2 <= 0;
            m_req_valid_ff2 <= 0;
            m_resp_rdata_ff1 <= 0;
            m_resp_slverr_ff1 <= 0;
        end else begin
            m_req_addr_ff2 <= m_req_addr_ff1;
            m_req_write_ff2 <= m_req_write_ff1;
            m_req_wdata_ff2 <= m_req_wdata_ff1;
            m_req_wstrb_ff2 <= m_req_wstrb_ff1;
            m_req_prot_ff2 <= m_req_prot_ff1;
            m_req_valid_ff2 <= m_req_valid_ff1;
            m_resp_rdata_ff1 <= M_APB_PRDATA;
            m_resp_slverr_ff1 <= M_APB_PSLVERR;
        end
    end

    // Second stage of two-stage flop-flop for M_APB to S_APB
    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            s_resp_rdata <= 0;
            s_resp_slverr <= 0;
        end else begin
            s_resp_rdata <= m_resp_rdata_ff1;
            s_resp_slverr <= m_resp_slverr_ff1;
        end
    end

    // Drive S_APB side response signals
    assign S_APB_PRDATA = s_resp_rdata;
    assign S_APB_PSLVERR = s_resp_slverr;

    // Drive M_APB side request signals
    assign M_APB_PADDR = m_req_addr_ff2;
    assign M_APB_PWRITE = m_req_write_ff2;
    assign M_APB_PWDATA = m_req_wdata_ff2;
    assign M_APB_PWSTRB = m_req_wstrb_ff2;
    assign M_APB_PPROT = m_req_prot_ff2;

    // Ready signals
    assign m_req_ready_ff2 = M_APB_PREADY;

endmodule
