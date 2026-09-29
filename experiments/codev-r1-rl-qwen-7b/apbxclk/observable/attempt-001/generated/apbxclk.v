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

    // S_APB domain signals
    reg [AW-1:0] s_addr;
    reg [DW-1:0] s_wdata;
    reg s_write;
    reg [(DW/8)-1:0] s_pstrb;
    reg [2:0] s_pprot;
    reg s_pready;

    // CDC signals
    reg req_toggle;
    reg done_toggle;
    reg done_toggle_sync1, done_toggle_sync2;

    // M_APB domain signals
    reg req_toggle_sync1, req_toggle_sync2;
    reg [AW-1:0] m_addr;
    reg m_write;
    reg [DW-1:0] m_wdata;
    reg [(DW/8)-1:0] m_pstrb;
    reg [2:0] m_pprot;
    reg [1:0] state;
    reg done_toggle_m;

    // Assign M_APB outputs
    assign M_APB_PADDR = m_addr;
    assign M_APB_PWRITE = m_write;
    assign M_APB_PWDATA = m_wdata;
    assign M_APB_PWSTRB = m_pstrb;
    assign M_APB_PPROT = m_pprot;

    // Assign S_APB_PREADY
    assign S_APB_PREADY = s_pready;

    // Assign S_APB_PRDATA and PSLVERR
    assign S_APB_PRDATA = M_APB_PRDATA;
    assign S_APB_PSLVERR = M_APB_PSLVERR;

    // S_APB side: Capture transfer and generate request
    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            s_addr <= 0;
            s_wdata <= 0;
            s_write <= 0;
            s_pstrb <= 0;
            s_pprot <= 0;
            s_pready <= 1'b1;
            req_toggle <= 0;
        end else begin
            if (S_APB_PSEL && S_APB_PENABLE && !s_pready) begin
                s_addr <= S_APB_PADDR;
                s_wdata <= S_APB_PWDATA;
                s_write <= S_APB_PWRITE;
                s_pstrb <= S_APB_PWSTRB;
                s_pprot <= S_APB_PPROT;
                req_toggle <= ~req_toggle;
                s_pready <= 1'b0;
            end else if (done_toggle_sync2) begin
                s_pready <= 1'b1;
            end
        end
    end

    // CDC: Synchronize req_toggle to M_APB domain
    always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
        if (!M_PRESETn) begin
            req_toggle_sync1 <= 0;
            req_toggle_sync2 <= 0;
        end else begin
            req_toggle_sync1 <= req_toggle;
            req_toggle_sync2 <= req_toggle_sync1;
        end
    end

    // M_APB side state machine
    always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
        if (!M_PRESETn) begin
            state <= 0;
            M_APB_PSEL <= 0;
            M_APB_PENABLE <= 0;
            m_addr <= 0;
            m_write <= 0;
            m_wdata <= 0;
            m_pstrb <= 0;
            m_pprot <= 0;
            done_toggle_m <= 0;
        end else begin
            case (state)
                0: begin // Idle
                    if (req_toggle_sync2) begin
                        m_addr <= s_addr;
                        m_write <= s_write;
                        m_wdata <= s_wdata;
                        m_pstrb <= s_pstrb;
                        m_pprot <= s_pprot;
                        M_APB_PSEL <= 1;
                        M_APB_PENABLE <= 0;
                        state <= 1;
                    end
                end
                1: begin // Setup phase
                    M_APB_PENABLE <= 1;
                    state <= 2;
                end
                2: begin // Access phase
                    if (M_APB_PREADY) begin
                        done_toggle_m <= ~done_toggle_m;
                        M_APB_PSEL <= 0;
                        M_APB_PENABLE <= 0;
                        state <= 0;
                    end
                end
            endcase
        end
    end

    // CDC: Synchronize done_toggle to S_APB domain
    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            done_toggle_sync1 <= 0;
            done_toggle_sync2 <= 0;
        end else begin
            done_toggle_sync1 <= done_toggle_m;
            done_toggle_sync2 <= done_toggle_sync1;
        end
    end

endmodule
