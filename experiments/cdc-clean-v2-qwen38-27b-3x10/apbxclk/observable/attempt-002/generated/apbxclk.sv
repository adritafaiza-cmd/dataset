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

    // 2-FF synchronizers
    reg [1:0] sync_req;
    reg [1:0] sync_done;

    always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
        if (!M_PRESETn)
            sync_req <= 2'b00;
        else
            sync_req <= {sync_req[0], S_APB_PSEL};
    end

    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn)
            sync_done <= 2'b00;
        else
            sync_done <= {sync_done[0], M_APB_PSEL};
    end

    // Master-side state machine
    localparam MS_IDLE = 2'd0;
    localparam MS_SETUP = 2'd1;
    localparam MS_ACCESS = 2'd2;
    localparam MS_DONE = 2'd3;

    reg [1:0] m_state;
    reg [AW-1:0] m_addr;
    reg m_write;
    reg [DW-1:0] m_wdata;
    reg [DW/8-1:0] m_wstrb;
    reg [2:0] m_pprot;
    reg [DW-1:0] m_rdata;
    reg m_pslverr;

    always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
        if (!M_PRESETn) begin
            m_state <= MS_IDLE;
            m_addr <= {AW{1'b0}};
            m_write <= 1'b0;
            m_wdata <= {DW{1'b0}};
            m_wstrb <= {(DW/8){1'b0}};
            m_pprot <= 3'b000;
            m_rdata <= {DW{1'b0}};
            m_pslverr <= 1'b0;
        end else begin
            case (m_state)
                MS_IDLE: begin
                    if (sync_req[1]) begin
                        m_addr <= S_APB_PADDR;
                        m_write <= S_APB_PWRITE;
                        m_wdata <= S_APB_PWDATA;
                        m_wstrb <= S_APB_PWSTRB;
                        m_pprot <= S_APB_PPROT;
                        m_state <= MS_SETUP;
                    end
                end
                MS_SETUP: begin
                    m_state <= MS_ACCESS;
                end
                MS_ACCESS: begin
                    if (M_APB_PREADY) begin
                        m_rdata <= M_APB_PRDATA;
                        m_pslverr <= M_APB_PSLVERR;
                        m_state <= MS_DONE;
                    end
                end
                MS_DONE: begin
                    m_state <= MS_IDLE;
                end
                default: m_state <= MS_IDLE;
            endcase
        end
    end

    // Master APB outputs
    always @(*) begin
        M_APB_PSEL = (m_state == MS_SETUP) || (m_state == MS_ACCESS);
        M_APB_PENABLE = (m_state == MS_ACCESS);
        M_APB_PADDR = m_addr;
        M_APB_PWRITE = m_write;
        M_APB_PWDATA = m_wdata;
        M_APB_PWSTRB = m_wstrb;
        M_APB_PPROT = m_pprot;
    end

    // Slave-side state machine
    localparam SS_IDLE = 2'd0;
    localparam SS_WAIT = 2'd1;
    localparam SS_RESP = 2'd2;

    reg [1:0] s_state;
    reg [DW-1:0] s_rdata;
    reg s_pslverr;

    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            s_state <= SS_IDLE;
            s_rdata <= {DW{1'b0}};
            s_pslverr <= 1'b0;
        end else begin
            case (s_state)
                SS_IDLE: begin
                    if (S_APB_PSEL) begin
                        s_state <= SS_WAIT;
                    end
                end
                SS_WAIT: begin
                    if (sync_done[1]) begin
                        s_rdata <= M_APB_PRDATA;
                        s_pslverr <= M_APB_PSLVERR;
                        s_state <= SS_RESP;
                    end
                end
                SS_RESP: begin
                    if (S_APB_PENABLE) begin
                        s_state <= SS_IDLE;
                    end
                end
                default: s_state <= SS_IDLE;
            endcase
        end
    end

    // Slave APB outputs
    always @(*) begin
        S_APB_PREADY = (s_state == SS_RESP);
        S_APB_PRDATA = s_rdata;
        S_APB_PSLVERR = s_pslverr;
    end

endmodule
