module apbxclk #(
        parameter   C_APB_ADDR_WIDTH = 12,
        parameter   C_APB_DATA_WIDTH = 32,
        parameter [0:0] OPT_REGISTERED = 1'b0,
        localparam  AW = C_APB_ADDR_WIDTH,
        localparam  DW = C_APB_DATA_WIDTH
    ) (
        input   wire            S_APB_PCLK, S_PRESETn,
        input   wire            S_APB_PSEL,
        input   wire            S_APB_PENABLE,
        output  reg             S_APB_PREADY,
        input   wire    [AW-1:0] S_APB_PADDR,
        input   wire            S_APB_PWRITE,
        input   wire    [DW-1:0] S_APB_PWDATA,
        input   wire    [DW/8-1:0] S_APB_PWSTRB,
        input   wire    [2:0]    S_APB_PPROT,
        output  wire    [DW-1:0] S_APB_PRDATA,
        output  wire            S_APB_PSLVERR,
        input   wire            M_APB_PCLK,
        output  reg             M_PRESETn,
        output  reg             M_APB_PSEL,
        output  reg             M_APB_PENABLE,
        input   wire            M_APB_PREADY,
        output  wire    [AW-1:0] M_APB_PADDR,
        output  wire            M_APB_PWRITE,
        output  wire    [DW-1:0] M_APB_PWDATA,
        output  wire    [DW/8-1:0] M_APB_PWSTRB,
        output  wire    [2:0]    M_APB_PPROT,
        input   wire    [DW-1:0] M_APB_PRDATA,
        input   wire            M_APB_PSLVERR
    );

    // Internal signals
    reg [AW-1:0] s_apb_addr_reg;
    reg          s_apb_pwrite_reg;
    reg [DW-1:0] s_apb_pwdata_reg;
    reg [DW/8-1:0] s_apb_pwstrb_reg;
    reg [2:0]    s_apb_pprot_reg;
    reg [DW-1:0] m_apb_prdata_reg;
    reg          m_apb_pslverr_reg;
    reg          s_apb_request_valid;
    reg          s_apb_request_ready;
    reg          m_apb_request_valid;
    reg          m_apb_request_ready;

    // S_APB domain
    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            S_APB_PREADY <= 1'b0;
            s_apb_request_valid <= 1'b0;
            s_apb_addr_reg <= {AW{1'b0}};
            s_apb_pwrite_reg <= 1'b0;
            s_apb_pwdata_reg <= {DW{1'b0}};
            s_apb_pwstrb_reg <= {DW/8{1'b0}};
            s_apb_pprot_reg <= 3'b000;
        end else begin
            if (S_APB_PSEL && S_APB_PENABLE) begin
                if (s_apb_request_ready) begin
                    s_apb_addr_reg <= S_APB_PADDR;
                    s_apb_pwrite_reg <= S_APB_PWRITE;
                    s_apb_pwdata_reg <= S_APB_PWDATA;
                    s_apb_pwstrb_reg <= S_APB_PWSTRB;
                    s_apb_pprot_reg <= S_APB_PPROT;
                    s_apb_request_valid <= 1'b1;
                end else begin
                    s_apb_request_valid <= 1'b0;
                end
            end else begin
                s_apb_request_valid <= 1'b0;
            end

            if (m_apb_request_ready) begin
                S_APB_PREADY <= 1'b1;
            end else begin
                S_APB_PREADY <= 1'b0;
            end
        end
    end

    // M_APB domain
    always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            M_PRESETn <= 1'b0;
            M_APB_PSEL <= 1'b0;
            M_APB_PENABLE <= 1'b0;
            m_apb_request_valid <= 1'b0;
            m_apb_prdata_reg <= {DW{1'b0}};
            m_apb_pslverr_reg <= 1'b0;
        end else begin
            M_PRESETn <= 1'b1;

            if (s_apb_request_valid && !m_apb_request_valid) begin
                M_APB_PSEL <= 1'b1;
                M_APB_PADDR <= s_apb_addr_reg;
                M_APB_PWRITE <= s_apb_pwrite_reg;
                M_APB_PWDATA <= s_apb_pwdata_reg;
                M_APB_PWSTRB <= s_apb_pwstrb_reg;
                M_APB_PPROT <= s_apb_pprot_reg;
                m_apb_request_valid <= 1'b1;
            end else if (M_APB_PREADY) begin
                M_APB_PSEL <= 1'b0;
                M_APB_PENABLE <= 1'b0;
                m_apb_request_valid <= 1'b0;
                m_apb_prdata_reg <= M_APB_PRDATA;
                m_apb_pslverr_reg <= M_APB_PSLVERR;
            end else if (m_apb_request_valid) begin
                M_APB_PENABLE <= 1'b1;
            end
        end
    end

    // Ready signals
    always @(*) begin
        s_apb_request_ready = !m_apb_request_valid;
        m_apb_request_ready = M_APB_PREADY;
    end

    // Outputs
    assign S_APB_PRDATA = m_apb_prdata_reg;
    assign S_APB_PSLVERR = m_apb_pslverr_reg;
    assign M_APB_PADDR = s_apb_addr_reg;
    assign M_APB_PWRITE = s_apb_pwrite_reg;
    assign M_APB_PWDATA = s_apb_pwdata_reg;
    assign M_APB_PWSTRB = s_apb_pwstrb_reg;
    assign M_APB_PPROT = s_apb_pprot_reg;

endmodule
