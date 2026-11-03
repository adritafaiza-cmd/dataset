module apbxclk #(
        parameter C_APB_ADDR_WIDTH = 12,
        parameter C_APB_DATA_WIDTH = 32,
        parameter [0:0] OPT_REGISTERED = 1'b0,
        localparam AW = C_APB_ADDR_WIDTH,
        localparam DW = C_APB_DATA_WIDTH
    ) (
        input wire S_APB_PCLK, S_PRESETn,
        input wire S_APB_PSEL,
        input wire S_APB_PENABLE,
        output reg S_APB_PREADY,
        input wire [AW-1:0] S_APB_PADDR,
        input wire S_APB_PWRITE,
        input wire [DW-1:0] S_APB_PWDATA,
        input wire [DW/8-1:0] S_APB_PWSTRB,
        input wire [2:0] S_APB_PPROT,
        output wire [DW-1:0] S_APB_PRDATA,
        output wire S_APB_PSLVERR,
        input wire M_APB_PCLK,
        output reg M_PRESETn,
        output reg M_APB_PSEL,
        output reg M_APB_PENABLE,
        input wire M_APB_PREADY,
        output wire [AW-1:0] M_APB_PADDR,
        output wire M_APB_PWRITE,
        output wire [DW-1:0] M_APB_PWDATA,
        output wire [DW/8-1:0] M_APB_PWSTRB,
        output wire [2:0] M_APB_PPROT,
        input wire [DW-1:0] M_APB_PRDATA,
        input wire M_APB_PSLVERR
    );

    // Internal signals for clock-domain crossing
    reg [AW-1:0] s_apb_paddr_reg;
    reg s_apb_pwrite_reg;
    reg [DW-1:0] s_apb_pwdata_reg;
    reg [DW/8-1:0] s_apb_pwstrb_reg;
    reg [2:0] s_apb_pprot_reg;

    reg [DW-1:0] m_apb_prdata_sync;
    reg m_apb_pslverr_sync;

    reg s_req_valid, s_req_ready;
    reg m_req_valid, m_req_ready;

    // S_APB_PCLK domain logic
    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            S_APB_PREADY <= 1'b0;
            s_req_valid <= 1'b0;
            s_req_ready <= 1'b0;
        end else begin
            S_APB_PREADY <= m_apb_pready_sync & s_req_valid;
            if (s_req_ready) begin
                s_req_valid <= 1'b0;
            end else if (S_APB_PSEL & S_APB_PENABLE & !s_req_valid) begin
                s_req_valid <= 1'b1;
            end

            if (s_req_ready) begin
                s_req_ready <= 1'b0;
            end else if (M_APB_PREADY & m_req_valid) begin
                s_req_ready <= 1'b1;
            end
        end
    end

    // M_APB_PCLK domain logic
    always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            M_PRESETn <= 1'b0;
            M_APB_PSEL <= 1'b0;
            M_APB_PENABLE <= 1'b0;
            m_req_valid <= 1'b0;
            m_req_ready <= 1'b0;
        end else begin
            M_PRESETn <= 1'b1;
            M_APB_PSEL <= s_req_valid & !m_req_valid;
            M_APB_PENABLE <= s_req_valid & !m_req_valid;

            if (m_req_ready) begin
                m_req_valid <= 1'b0;
            end else if (M_APB_PREADY & m_req_valid) begin
                m_req_valid <= 1'b0;
            end else if (s_req_valid & !m_req_valid) begin
                m_req_valid <= 1'b1;
                s_apb_paddr_reg <= S_APB_PADDR;
                s_apb_pwrite_reg <= S_APB_PWRITE;
                s_apb_pwdata_reg <= S_APB_PWDATA;
                s_apb_pwstrb_reg <= S_APB_PWSTRB;
                s_apb_pprot_reg <= S_APB_PPROT;
            end

            if (m_req_ready) begin
                m_req_ready <= 1'b0;
            end else if (M_APB_PREADY & m_req_valid) begin
                m_req_ready <= 1'b1;
            end
        end
    end

    // Clock-domain crossing for M_APB_PREADY to S_APB_PCLK
    reg m_apb_pready_reg1, m_apb_pready_reg2;
    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            m_apb_pready_reg1 <= 1'b0;
            m_apb_pready_reg2 <= 1'b0;
        end else begin
            m_apb_pready_reg1 <= M_APB_PREADY;
            m_apb_pready_reg2 <= m_apb_pready_reg1;
        end
    end
    assign m_apb_pready_sync = m_apb_pready_reg2;

    // Clock-domain crossing for M_APB_PRDATA and M_APB_PSLVERR to S_APB_PCLK
    reg [DW-1:0] m_apb_prdata_reg1, m_apb_prdata_reg2;
    reg m_apb_pslverr_reg1, m_apb_pslverr_reg2;
    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            m_apb_prdata_reg1 <= 32'b0;
            m_apb_prdata_reg2 <= 32'b0;
            m_apb_pslverr_reg1 <= 1'b0;
            m_apb_pslverr_reg2 <= 1'b0;
        end else begin
            m_apb_prdata_reg1 <= M_APB_PRDATA;
            m_apb_prdata_reg2 <= m_apb_prdata_reg1;
            m_apb_pslverr_reg1 <= M_APB_PSLVERR;
            m_apb_pslverr_reg2 <= m_apb_pslverr_reg1;
        end
    end
    assign m_apb_prdata_sync = m_apb_prdata_reg2;
    assign m_apb_pslverr_sync = m_apb_pslverr_reg2;

    // Assign outputs
    assign S_APB_PRDATA = m_apb_prdata_sync;
    assign S_APB_PSLVERR = m_apb_pslverr_sync;

    assign M_APB_PADDR = s_apb_paddr_reg;
    assign M_APB_PWRITE = s_apb_pwrite_reg;
    assign M_APB_PWDATA = s_apb_pwdata_reg;
    assign M_APB_PWSTRB = s_apb_pwstrb_reg;
    assign M_APB_PPROT = s_apb_pprot_reg;

endmodule
