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

    // Internal signals
    reg s_apb_req;
    reg s_apb_ack;
    reg m_apb_req;
    reg m_apb_ack;
    reg [AW-1:0] s_apb_addr;
    reg s_apb_write;
    reg [DW-1:0] s_apb_wdata;
    reg [DW/8-1:0] s_apb_wstrb;
    reg [2:0] s_apb_prot;
    reg [AW-1:0] m_apb_addr;
    reg m_apb_write;
    reg [DW-1:0] m_apb_wdata;
    reg [DW/8-1:0] m_apb_wstrb;
    reg [2:0] m_apb_prot;
    reg [DW-1:0] m_apb_rdata;
    reg m_apb_slverr;
    reg [DW-1:0] s_apb_rdata;
    reg s_apb_slverr;
    reg s_apb_setup_done;
    reg s_apb_access_done;
    reg m_apb_setup_done;
    reg m_apb_access_done;

    // Source APB domain
    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            s_apb_req <= 0;
            s_apb_setup_done <= 0;
            s_apb_access_done <= 0;
            S_APB_PREADY <= 0;
        end else begin
            // Capture request setup phase
            if (S_APB_PSEL && !S_APB_PENABLE && !s_apb_setup_done) begin
                s_apb_addr <= S_APB_PADDR;
                s_apb_write <= S_APB_PWRITE;
                s_apb_wdata <= S_APB_PWDATA;
                s_apb_wstrb <= S_APB_PWSTRB;
                s_apb_prot <= S_APB_PPROT;
                s_apb_req <= 1;
                s_apb_setup_done <= 1;
            end

            // Capture request access phase
            if (S_APB_PSEL && S_APB_PENABLE && !s_apb_access_done) begin
                s_apb_access_done <= 1;
            end

            // Generate S_APB_PREADY
            if (s_apb_access_done && m_apb_access_done) begin
                S_APB_PREADY <= 1;
                s_apb_setup_done <= 0;
                s_apb_access_done <= 0;
                m_apb_access_done <= 0;
            end else begin
                S_APB_PREADY <= 0;
            end
        end
    end

    // Destination APB domain
    always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            M_PRESETn <= 0;
            M_APB_PSEL <= 0;
            M_APB_PENABLE <= 0;
            m_apb_req <= 0;
            m_apb_setup_done <= 0;
            m_apb_access_done <= 0;
        end else begin
            M_PRESETn <= 1;

            // Forward request setup phase
            if (s_apb_req && !m_apb_setup_done) begin
                m_apb_addr <= s_apb_addr;
                m_apb_write <= s_apb_write;
                m_apb_wdata <= s_apb_wdata;
                m_apb_wstrb <= s_apb_wstrb;
                m_apb_prot <= s_apb_prot;
                m_apb_req <= 1;
                M_APB_PSEL <= 1;
                m_apb_setup_done <= 1;
            end

            // Forward request access phase
            if (m_apb_setup_done && !m_apb_access_done) begin
                M_APB_PENABLE <= 1;
                if (M_APB_PREADY) begin
                    m_apb_setup_done <= 0;
                    m_apb_access_done <= 1;
                end
            end

            // Capture response
            if (m_apb_access_done) begin
                m_apb_rdata <= M_APB_PRDATA;
                m_apb_slverr <= M_APB_PSLVERR;
                M_APB_PSEL <= 0;
                M_APB_PENABLE <= 0;
                s_apb_rdata <= m_apb_rdata;
                s_apb_slverr <= m_apb_slverr;
            end
        end
    end

    // Register crossing if OPT_REGISTERED is set
    reg [DW-1:0] reg_s_apb_rdata;
    reg reg_s_apb_slverr;
    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            reg_s_apb_rdata <= 0;
            reg_s_apb_slverr <= 0;
        end else if (m_apb_access_done) begin
            reg_s_apb_rdata <= m_apb_rdata;
            reg_s_apb_slverr <= m_apb_slverr;
        end
    end

    assign S_APB_PRDATA = OPT_REGISTERED ? reg_s_apb_rdata : s_apb_rdata;
    assign S_APB_PSLVERR = OPT_REGISTERED ? reg_s_apb_slverr : s_apb_slverr;

endmodule
