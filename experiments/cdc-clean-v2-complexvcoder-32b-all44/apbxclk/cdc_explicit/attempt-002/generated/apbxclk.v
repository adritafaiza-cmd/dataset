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

    // Internal signals for synchronization
    reg [AW-1:0] s_apb_paddr_sync;
    reg s_apb_pwrite_sync;
    reg [DW-1:0] s_apb_pwdata_sync;
    reg [DW/8-1:0] s_apb_pwstrb_sync;
    reg [2:0] s_apb_pprot_sync;

    reg s_apb_psel_reg;
    reg s_apb_penable_reg;

    reg m_apb_pready_sync;
    reg [DW-1:0] m_apb_prdata_sync;
    reg m_apb_pslverr_sync;

    // Cross-clock synchronization registers
    reg [AW-1:0] s_apb_paddr_reg;
    reg s_apb_pwrite_reg;
    reg [DW-1:0] s_apb_pwdata_reg;
    reg [DW/8-1:0] s_apb_pwstrb_reg;
    reg [2:0] s_apb_pprot_reg;

    reg [AW-1:0] m_apb_paddr_reg;
    reg m_apb_pwrite_reg;
    reg [DW-1:0] m_apb_pwdata_reg;
    reg [DW/8-1:0] m_apb_pwstrb_reg;
    reg [2:0] m_apb_pprot_reg;

    reg [DW-1:0] m_apb_prdata_reg;
    reg m_apb_pslverr_reg;

    // Synchronization logic from S_APB to M_APB
    always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            s_apb_paddr_reg <= 0;
            s_apb_pwrite_reg <= 0;
            s_apb_pwdata_reg <= 0;
            s_apb_pwstrb_reg <= 0;
            s_apb_pprot_reg <= 0;
            s_apb_psel_reg <= 0;
            s_apb_penable_reg <= 0;
        end else begin
            s_apb_paddr_reg <= S_APB_PADDR;
            s_apb_pwrite_reg <= S_APB_PWRITE;
            s_apb_pwdata_reg <= S_APB_PWDATA;
            s_apb_pwstrb_reg <= S_APB_PWSTRB;
            s_apb_pprot_reg <= S_APB_PPROT;
            if (S_APB_PSEL && S_APB_PENABLE) begin
                s_apb_psel_reg <= 1;
                s_apb_penable_reg <= 1;
            end else begin
                s_apb_psel_reg <= 0;
                s_apb_penable_reg <= 0;
            end
        end
    end

    always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            s_apb_paddr_sync <= 0;
            s_apb_pwrite_sync <= 0;
            s_apb_pwdata_sync <= 0;
            s_apb_pwstrb_sync <= 0;
            s_apb_pprot_sync <= 0;
        end else begin
            s_apb_paddr_sync <= s_apb_paddr_reg;
            s_apb_pwrite_sync <= s_apb_pwrite_reg;
            s_apb_pwdata_sync <= s_apb_pwdata_reg;
            s_apb_pwstrb_sync <= s_apb_pwstrb_reg;
            s_apb_pprot_sync <= s_apb_pprot_reg;
        end
    end

    // M_APB interface logic
    always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
        if (!M_PRESETn) begin
            M_PRESETn <= 1'b0;
            M_APB_PSEL <= 1'b0;
            M_APB_PENABLE <= 1'b0;
            M_APB_PADDR <= 0;
            M_APB_PWRITE <= 0;
            M_APB_PWDATA <= 0;
            M_APB_PWSTRB <= 0;
            M_APB_PPROT <= 0;
        end else begin
            M_PRESETn <= 1'b1;
            M_APB_PSEL <= s_apb_psel_sync;
            M_APB_PENABLE <= s_apb_penable_sync;
            M_APB_PADDR <= s_apb_paddr_sync;
            M_APB_PWRITE <= s_apb_pwrite_sync;
            M_APB_PWDATA <= s_apb_pwdata_sync;
            M_APB_PWSTRB <= s_apb_pwstrb_sync;
            M_APB_PPROT <= s_apb_pprot_sync;
        end
    end

    // Synchronization logic from M_APB to S_APB
    always @(posedge S_APB_PCLK or negedge M_PRESETn) begin
        if (!M_PRESETn) begin
            m_apb_pready_reg <= 0;
            m_apb_prdata_reg <= 0;
            m_apb_pslverr_reg <= 0;
        end else begin
            m_apb_pready_reg <= M_APB_PREADY;
            m_apb_prdata_reg <= M_APB_PRDATA;
            m_apb_pslverr_reg <= M_APB_PSLVERR;
        end
    end

    always @(posedge S_APB_PCLK or negedge M_PRESETn) begin
        if (!M_PRESETn) begin
            m_apb_pready_sync <= 0;
            m_apb_prdata_sync <= 0;
            m_apb_pslverr_sync <= 0;
        end else begin
            m_apb_pready_sync <= m_apb_pready_reg;
            m_apb_prdata_sync <= m_apb_prdata_reg;
            m_apb_pslverr_sync <= m_apb_pslverr_reg;
        end
    end

    // S_APB interface logic
    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            S_APB_PREADY <= 1'b0;
            S_APB_PRDATA <= 0;
            S_APB_PSLVERR <= 0;
        end else begin
            S_APB_PREADY <= m_apb_pready_sync;
            S_APB_PRDATA <= m_apb_prdata_sync;
            S_APB_PSLVERR <= m_apb_pslverr_sync;
        end
    end

    // Assign control signals for M_APB
    assign s_apb_penable_sync = s_apb_penable_reg;

endmodule
