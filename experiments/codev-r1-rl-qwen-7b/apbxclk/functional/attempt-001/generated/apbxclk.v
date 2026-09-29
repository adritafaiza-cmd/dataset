module apbxclk #(
    parameter C_APB_ADDR_WIDTH = 12,
    parameter C_APB_DATA_WIDTH = 32,
    parameter [0:0] OPT_REGISTERED = 1'b0,
    localparam AW = C_APB_ADDR_WIDTH,
    localparam DW = C_APB_DATA_WIDTH
) (
    input wire S_APB_PCLK,
    input wire S_PRESETn,
    input wire S_APB_PSEL,
    input wire S_APB_PENABLE,
    output wire S_APB_PREADY,
    input wire [AW-1:0] S_APB_PADDR,
    input wire S_APB_PWRITE,
    input wire [DW-1:0] S_APB_PWDATA,
    input wire [(DW/8)-1:0] S_APB_PWSTRB,
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
    output wire [(DW/8)-1:0] M_APB_PWSTRB,
    output wire [2:0] M_APB_PPROT,
    input wire [DW-1:0] M_APB_PRDATA,
    input wire M_APB_PSLVERR
);

    // S_APB domain registers
    reg [AW-1:0] s_addr_reg;
    reg [DW-1:0] s_wdata_reg;
    reg [(DW/8)-1:0] s_wstrb_reg;
    reg s_pwrite_reg;
    reg [2:0] s_pprot_reg;
    reg s_psel_reg;
    reg s_penable_reg;

    // M_APB domain signals
    reg req_sync1, req_sync2;
    reg [AW-1:0] m_addr_reg;
    reg [DW-1:0] m_wdata_reg;
    reg [(DW/8)-1:0] m_wstrb_reg;
    reg m_pwrite_reg;
    reg [2:0] m_pprot_reg;
    reg ack;

    // S_APB domain synchronization
    reg ack_sync1, ack_sync2;

    // M_APB domain state machine
    localparam M_IDLE = 0;
    localparam M_SETUP = 1;
    localparam M_ACCESS = 2;
    reg [1:0] m_state;

    // S_APB domain logic
    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            s_psel_reg <= 0;
            s_penable_reg <= 0;
            s_addr_reg <= 0;
            s_wdata_reg <= 0;
            s_wstrb_reg <= 0;
            s_pwrite_reg <= 0;
            s_pprot_reg <= 0;
        end else begin
            if (S_APB_PSEL && !S_APB_PENABLE) begin
                s_addr_reg <= S_APB_PADDR;
                s_wdata_reg <= S_APB_PWDATA;
                s_wstrb_reg <= S_APB_PWSTRB;
                s_pwrite_reg <= S_APB_PWRITE;
                s_pprot_reg <= S_APB_PPROT;
                s_psel_reg <= 1;
                s_penable_reg <= 0;
            end else if (S_APB_PENABLE && !S_APB_PREADY) begin
                s_penable_reg <= 1;
            end else if (S_APB_PREADY) begin
                s_psel_reg <= 0;
                s_penable_reg <= 0;
            end
        end
    end

    // M_APB domain synchronization
    always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
        if (!M_PRESETn) begin
            req_sync1 <= 0;
            req_sync2 <= 0;
            M_PRESETn <= 0;
            M_APB_PSEL <= 0;
            M_APB_PENABLE <= 0;
            m_state <= M_IDLE;
            ack <= 0;
            m_addr_reg <= 0;
            m_wdata_reg <= 0;
            m_wstrb_reg <= 0;
            m_pwrite_reg <= 0;
            m_pprot_reg <= 0;
        end else begin
            M_PRESETn <= 1;
            ack <= 0;
            req_sync1 <= s_psel_reg;
            req_sync2 <= req_sync1;

            case (m_state)
                M_IDLE: begin
                    if (req_sync2) begin
                        m_addr_reg <= s_addr_reg;
                        m_wdata_reg <= s_wdata_reg;
                        m_wstrb_reg <= s_wstrb_reg;
                        m_pwrite_reg <= s_pwrite_reg;
                        m_pprot_reg <= s_pprot_reg;
                        M_APB_PSEL <= 1;
                        M_APB_PENABLE <= 0;
                        m_state <= M_SETUP;
                    end
                end
                M_SETUP: begin
                    if (M_APB_PREADY) begin
                        M_APB_PENABLE <= 1;
                        m_state <= M_ACCESS;
                    end
                end
                M_ACCESS: begin
                    if (M_APB_PREADY) begin
                        M_APB_PSEL <= 0;
                        M_APB_PENABLE <= 0;
                        ack <= 1;
                        m_state <= M_IDLE;
                    end
                end
            endcase
        end
    end

    // OPT_REGISTERED handling
    generate
        if (OPT_REGISTERED) begin
            reg [AW-1:0] m_addr_reg;
            reg [DW-1:0] m_wdata_reg;
            reg [(DW/8)-1:0] m_wstrb_reg;
            reg m_pwrite_reg;
            reg [2:0] m_pprot_reg;

            always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
                if (!M_PRESETn) begin
                    m_addr_reg <= 0;
                    m_wdata_reg <= 0;
                    m_wstrb_reg <= 0;
                    m_pwrite_reg <= 0;
                    m_pprot_reg <= 0;
                end else begin
                    m_addr_reg <= m_addr_reg;
                    m_wdata_reg <= m_wdata_reg;
                    m_wstrb_reg <= m_wstrb_reg;
                    m_pwrite_reg <= m_pwrite_reg;
                    m_pprot_reg <= m_pprot_reg;
                end
            end

            assign M_APB_PADDR = m_addr_reg;
            assign M_APB_PWRITE = m_pwrite_reg;
            assign M_APB_PWDATA = m_wdata_reg;
            assign M_APB_PWSTRB = m_wstrb_reg;
            assign M_APB_PPROT = m_pprot_reg;
        end else begin
            assign M_APB_PADDR = m_addr_reg;
            assign M_APB_PWRITE = m_pwrite_reg;
            assign M_APB_PWDATA = m_wdata_reg;
            assign M_APB_PWSTRB = m_wstrb_reg;
            assign M_APB_PPROT = m_pprot_reg;
        end
    endgenerate

    // S_APB_PREADY synchronization
    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            ack_sync1 <= 0;
            ack_sync2 <= 0;
        end else begin
            ack_sync1 <= ack;
            ack_sync2 <= ack_sync1;
        end
    end

    assign S_APB_PREADY = ack_sync2;
    assign S_APB_PRDATA = M_APB_PRDATA;
    assign S_APB_PSLVERR = M_APB_PSLVERR;

endmodule
