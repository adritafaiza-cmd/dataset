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
    output reg S_APB_PREADY,
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

    // M_PRESETn generation
    reg [1:0] m_reset_sync;
    always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            m_reset_sync <= 2'b00;
        end else begin
            m_reset_sync <= {m_reset_sync[0], 1'b1};
        end
    end
    assign M_PRESETn = m_reset_sync[1];

    // S_APB domain logic
    reg s_start;
    reg [AW-1:0] s_addr_reg;
    reg s_write_reg;
    reg [DW-1:0] s_wdata_reg;
    reg [(DW/8)-1:0] s_wstrb_reg;
    reg [2:0] s_prot_reg;

    // Capture setup phase
    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            s_start <= 0;
            s_addr_reg <= 0;
            s_write_reg <= 0;
            s_wdata_reg <= 0;
            s_wstrb_reg <= 0;
            s_prot_reg <= 0;
        end else begin
            if (S_APB_PSEL && !S_APB_PENABLE) begin
                s_addr_reg <= S_APB_PADDR;
                s_write_reg <= S_APB_PWRITE;
                s_wdata_reg <= S_APB_PWDATA;
                s_wstrb_reg <= S_APB_PWSTRB;
                s_prot_reg <= S_APB_PPROT;
                s_start <= 1;
            end else begin
                s_start <= 0;
            end
        end
    end

    // Synchronize s_start to M_APB domain
    reg s_start_sync1, s_start_sync2;
    always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
        if (!M_PRESETn) begin
            s_start_sync1 <= 0;
            s_start_sync2 <= 0;
        end else begin
            s_start_sync1 <= s_start;
            s_start_sync2 <= s_start_sync1;
        end
    end

    // M_APB domain logic
    reg [1:0] m_state;
    localparam M_IDLE = 0;
    localparam M_SETUP = 1;
    localparam M_ACCESS = 2;

    reg [AW-1:0] m_addr_reg;
    reg m_write_reg;
    reg [DW-1:0] m_wdata_reg;
    reg [(DW/8)-1:0] m_wstrb_reg;
    reg [2:0] m_prot_reg;

    // Response registers
    reg [DW-1:0] m_prdata_reg;
    reg m_pslverr_reg;

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
            m_prdata_reg <= 0;
            m_pslverr_reg <= 0;
        end else begin
            case (m_state)
                M_IDLE: begin
                    if (s_start_sync2) begin
                        m_addr_reg <= s_addr_reg;
                        m_write_reg <= s_write_reg;
                        m_wdata_reg <= s_wdata_reg;
                        m_wstrb_reg <= s_wstrb_reg;
                        m_prot_reg <= s_prot_reg;
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
                        m_prdata_reg <= M_APB_PRDATA;
                        m_pslverr_reg <= M_APB_PSLVERR;
                        m_state <= M_IDLE;
                    end
                end
            endcase
        end
    end

    // Assign M_APB outputs
    assign M_APB_PADDR = m_addr_reg;
    assign M_APB_PWRITE = m_write_reg;
    assign M_APB_PWDATA = m_wdata_reg;
    assign M_APB_PWSTRB = m_wstrb_reg;
    assign M_APB_PPROT = m_prot_reg;

    // Synchronize done to S_APB domain
    reg s_done_sync1, s_done_sync2;
    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            s_done_sync1 <= 0;
            s_done_sync2 <= 0;
        end else begin
            s_done_sync1 <= (m_state == M_IDLE);
            s_done_sync2 <= s_done_sync1;
        end
    end

    // Assign S_APB outputs
    assign S_APB_PRDATA = m_prdata_reg;
    assign S_APB_PSLVERR = m_pslverr_reg;

    // Assert S_APB_PREADY when done
    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            S_APB_PREADY <= 0;
        end else begin
            S_APB_PREADY <= s_done_sync2;
        end
    end

endmodule
