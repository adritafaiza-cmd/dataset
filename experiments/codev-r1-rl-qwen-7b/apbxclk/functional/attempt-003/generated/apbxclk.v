module apbxclk #(
    parameter C_APB_ADDR_WIDTH = 12,
    parameter C_APB_DATA_WIDTH = 32,
    parameter [0:0] OPT_REGISTERED = 1'b0,
    localparam AW = C_APB_ADDR_WIDTH,
    localparam DW = C_APB_DATA_WIDTH
) (
    // S_APB Interface
    input wire S_APB_PCLK,
    input wire S_PRESETn,
    input wire S_APB_PSEL,
    input wire S_APB_PENABLE,
    output reg S_APB_PREADY,
    input wire [AW-1:0] S_APB_PADDR,
    input wire S_APB_PWRITE,
    input wire [DW-1:0] S_APB_PWDATA,
    input wire [(DW/8)-1:0] S_APB_PWSTRB,
    input wire [2:0] S_APB_PPROT,
    output wire [DW-1:0] S_APB_PRDATA,
    output wire S_APB_PSLVERR,

    // M_APB Interface
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

    // S_APB domain signals
    reg [AW-1:0] saddr_reg;
    reg swrite_reg;
    reg [DW-1:0] swdata_reg;
    reg [DW/8-1:0] swstrb_reg;
    reg [2:0] sprot_reg;
    reg req_s2m;
    reg ack_m2s_sync1, ack_m2s_sync2;

    // M_APB domain signals
    reg [AW-1:0] m_addr_reg;
    reg m_write_reg;
    reg [DW-1:0] m_wdata_reg;
    reg [DW/8-1:0] m_wstrb_reg;
    reg [2:0] m_prot_reg;
    reg m_psel_reg, m_penable_reg;
    reg [1:0] m_state;
    localparam M_IDLE = 0, M_SETUP = 1, M_ACCESS = 2;
    reg ack_m2s_reg;

    // Synchronization registers
    reg req_s2m_sync1, req_s2m_sync2;
    reg s_presetn_sync1, s_presetn_sync2;

    // Response registers for OPT_REGISTERED
    generate
        if (OPT_REGISTERED) begin
            reg [DW-1:0] s_prdata_reg;
            reg s_pslverr_reg;
            assign S_APB_PRDATA = s_prdata_reg;
            assign S_APB_PSLVERR = s_pslverr_reg;
        end else begin
            assign S_APB_PRDATA = M_APB_PRDATA;
            assign S_APB_PSLVERR = M_APB_PSLVERR;
        end
    endgenerate

    // S_APB FSM
    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            S_APB_PREADY <= 0;
            saddr_reg <= 0;
            swrite_reg <= 0;
            swdata_reg <= 0;
            swstrb_reg <= 0;
            sprot_reg <= 0;
            req_s2m <= 0;
            ack_m2s_sync1 <= 0;
            ack_m2s_sync2 <= 0;
        end else begin
            ack_m2s_sync1 <= ack_m2s_reg;
            ack_m2s_sync2 <= ack_m2s_sync1;

            if (S_APB_PREADY) S_APB_PREADY <= 0;

            if (S_APB_PSEL && !S_APB_PENABLE && !S_APB_PREADY) begin
                saddr_reg <= S_APB_PADDR;
                swrite_reg <= S_APB_PWRITE;
                swdata_reg <= S_APB_PWDATA;
                swstrb_reg <= S_APB_PWSTRB;
                sprot_reg <= S_APB_PPROT;
                req_s2m <= 1;
                S_APB_PREADY <= 0;
            end

            if (ack_m2s_sync2) begin
                S_APB_PREADY <= 1;
                req_s2m <= 0;
            end
        end
    end

    // M_APB FSM
    always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
        if (!M_PRESETn) begin
            m_state <= M_IDLE;
            M_APB_PSEL <= 0;
            M_APB_PENABLE <= 0;
            m_addr_reg <= 0;
            m_write_reg <= 0;
            m_wdata_reg <= 0;
            m_wstrb_reg <= 0;
            m_prot_reg <= 0;
            ack_m2s_reg <= 0;
        end else begin
            case (m_state)
                M_IDLE: begin
                    if (req_s2m_sync2) begin
                        m_addr_reg <= saddr_reg;
                        m_write_reg <= swrite_reg;
                        m_wdata_reg <= swdata_reg;
                        m_wstrb_reg <= swstrb_reg;
                        m_prot_reg <= sprot_reg;
                        M_APB_PSEL <= 1;
                        M_APB_PENABLE <= 0;
                        m_state <= M_SETUP;
                    end
                end
                M_SETUP: begin
                    M_APB_PENABLE <= 1;
                    m_state <= M_ACCESS;
                end
                M_ACCESS: begin
                    if (M_APB_PREADY) begin
                        M_APB_PSEL <= 0;
                        M_APB_PENABLE <= 0;
                        ack_m2s_reg <= 1;
                        m_state <= M_IDLE;
                        if (OPT_REGISTERED) begin
                            s_prdata_reg <= M_APB_PRDATA;
                            s_pslverr_reg <= M_APB_PSLVERR;
                        end
                    end
                end
            endcase
        end
    end

    // Synchronize req to M_APB domain
    always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
        if (!M_PRESETn) begin
            req_s2m_sync1 <= 0;
            req_s2m_sync2 <= 0;
        end else begin
            req_s2m_sync1 <= req_s2m;
            req_s2m_sync2 <= req_s2m_sync1;
        end
    end

    // Synchronize S_PRESETn to M_APB domain
    always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
        if (!M_PRESETn) begin
            s_presetn_sync1 <= 0;
            s_presetn_sync2 <= 0;
        end else begin
            s_presetn_sync1 <= S_PRESETn;
            s_presetn_sync2 <= s_presetn_sync1;
        end
    end

    assign M_PRESETn = s_presetn_sync2;

    // Assign M_APB outputs
    assign M_APB_PADDR = m_addr_reg;
    assign M_APB_PWRITE = m_write_reg;
    assign M_APB_PWDATA = m_wdata_reg;
    assign M_APB_PWSTRB = m_wstrb_reg;
    assign M_APB_PPROT = m_prot_reg;

endmodule
