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
    reg [1:0] s_apb_psel_sync, s_apb_penable_sync;
    reg [AW-1:0] s_apb_paddr_sync;
    reg s_apb_pwrite_sync;
    reg [DW-1:0] s_apb_pwdata_sync;
    reg [DW/8-1:0] s_apb_pwstrb_sync;
    reg [2:0] s_apb_pprot_sync;

    reg [1:0] m_apb_pready_sync;
    reg [DW-1:0] m_apb_prdata_sync;
    reg m_apb_pslverr_sync;

    // Registered values for crossing
    reg m_apb_psel_reg, m_apb_penable_reg;
    reg [AW-1:0] m_apb_paddr_reg;
    reg m_apb_pwrite_reg;
    reg [DW-1:0] m_apb_pwdata_reg;
    reg [DW/8-1:0] m_apb_pwstrb_reg;
    reg [2:0] m_apb_pprot_reg;

    reg m_apb_pready_reg;
    reg [DW-1:0] m_apb_prdata_reg;
    reg m_apb_pslverr_reg;

    // Next state registers
    reg m_apb_psel_reg_next, m_apb_penable_reg_next;
    reg [AW-1:0] m_apb_paddr_reg_next;
    reg m_apb_pwrite_reg_next;
    reg [DW-1:0] m_apb_pwdata_reg_next;
    reg [DW/8-1:0] m_apb_pwstrb_reg_next;
    reg [2:0] m_apb_pprot_reg_next;

    // Transaction in progress flag
    reg transaction_in_progress;

    // Synchronization from S_APB_PCLK to M_APB_PCLK
    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            s_apb_psel_sync <= 2'b00;
            s_apb_penable_sync <= 2'b00;
            s_apb_paddr_sync <= {AW{1'b0}};
            s_apb_pwrite_sync <= 1'b0;
            s_apb_pwdata_sync <= {DW{1'b0}};
            s_apb_pwstrb_sync <= {DW/8{1'b0}};
            s_apb_pprot_sync <= 3'b000;
        end else begin
            s_apb_psel_sync[0] <= S_APB_PSEL;
            s_apb_psel_sync[1] <= s_apb_psel_sync[0];
            s_apb_penable_sync[0] <= S_APB_PENABLE;
            s_apb_penable_sync[1] <= s_apb_penable_sync[0];
            s_apb_paddr_sync <= S_APB_PADDR;
            s_apb_pwrite_sync <= S_APB_PWRITE;
            s_apb_pwdata_sync <= S_APB_PWDATA;
            s_apb_pwstrb_sync <= S_APB_PWSTRB;
            s_apb_pprot_sync <= S_APB_PPROT;
        end
    end

    // Synchronization from M_APB_PCLK to S_APB_PCLK
    always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
        if (!M_PRESETn) begin
            m_apb_pready_sync <= 2'b00;
            m_apb_prdata_sync <= {DW{1'b0}};
            m_apb_pslverr_sync <= 1'b0;
        end else begin
            m_apb_pready_sync[0] <= M_APB_PREADY;
            m_apb_pready_sync[1] <= m_apb_pready_sync[0];
            m_apb_prdata_sync <= M_APB_PRDATA;
            m_apb_pslverr_sync <= M_APB_PSLVERR;
        end
    end

    // Register crossing values if OPT_REGISTERED is set
    always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
        if (!M_PRESETn) begin
            m_apb_psel_reg <= 1'b0;
            m_apb_penable_reg <= 1'b0;
            m_apb_paddr_reg <= {AW{1'b0}};
            m_apb_pwrite_reg <= 1'b0;
            m_apb_pwdata_reg <= {DW{1'b0}};
            m_apb_pwstrb_reg <= {DW/8{1'b0}};
            m_apb_pprot_reg <= 3'b000;

            m_apb_pready_reg <= 1'b0;
            m_apb_prdata_reg <= {DW{1'b0}};
            m_apb_pslverr_reg <= 1'b0;

            m_apb_psel_reg_next <= 1'b0;
            m_apb_penable_reg_next <= 1'b0;
            m_apb_paddr_reg_next <= {AW{1'b0}};
            m_apb_pwrite_reg_next <= 1'b0;
            m_apb_pwdata_reg_next <= {DW{1'b0}};
            m_apb_pwstrb_reg_next <= {DW/8{1'b0}};
            m_apb_pprot_reg_next <= 3'b000;

            transaction_in_progress <= 1'b0;
        end else begin
            // Capture synchronized values
            if (OPT_REGISTERED) begin
                m_apb_psel_reg <= s_apb_psel_sync[1];
                m_apb_penable_reg <= s_apb_penable_sync[1];
                m_apb_paddr_reg <= s_apb_paddr_sync;
                m_apb_pwrite_reg <= s_apb_pwrite_sync;
                m_apb_pwdata_reg <= s_apb_pwdata_sync;
                m_apb_pwstrb_reg <= s_apb_pwstrb_sync;
                m_apb_pprot_reg <= s_apb_pprot_sync;
            end else begin
                m_apb_psel_reg <= s_apb_psel_sync[1];
                m_apb_penable_reg <= s_apb_penable_sync[1];
                m_apb_paddr_reg <= s_apb_paddr_sync;
                m_apb_pwrite_reg <= s_apb_pwrite_sync;
                m_apb_pwdata_reg <= s_apb_pwdata_sync;
                m_apb_pwstrb_reg <= s_apb_pwstrb_sync;
                m_apb_pprot_reg <= s_apb_pprot_sync;
            end

            // Forward the transaction to M_APB
            if (m_apb_penable_reg && !transaction_in_progress) begin
                transaction_in_progress <= 1'b1;
                m_apb_psel_reg_next <= m_apb_psel_reg;
                m_apb_penable_reg_next <= m_apb_penable_reg;
                m_apb_paddr_reg_next <= m_apb_paddr_reg;
                m_apb_pwrite_reg_next <= m_apb_pwrite_reg;
                m_apb_pwdata_reg_next <= m_apb_pwdata_reg;
                m_apb_pwstrb_reg_next <= m_apb_pwstrb_reg;
                m_apb_pprot_reg_next <= m_apb_pprot_reg;
            end

            // Hold the transaction stable until M_APB_PREADY is asserted
            if (m_apb_pready_sync[1] && transaction_in_progress) begin
                transaction_in_progress <= 1'b0;
                m_apb_pready_reg <= m_apb_pready_sync[1];
                m_apb_prdata_reg <= m_apb_prdata_sync;
                m_apb_pslverr_reg <= m_apb_pslverr_sync;
            end
        end
    end

    // Output assignments
    assign S_APB_PREADY = m_apb_pready_reg;
    assign S_APB_PRDATA = m_apb_prdata_reg;
    assign S_APB_PSLVERR = m_apb_pslverr_reg;
    assign M_PRESETn = S_PRESETn;
    assign M_APB_PSEL = m_apb_psel_reg_next;
    assign M_APB_PENABLE = m_apb_penable_reg_next;
    assign M_APB_PADDR = m_apb_paddr_reg_next;
    assign M_APB_PWRITE = m_apb_pwrite_reg_next;
    assign M_APB_PWDATA = m_apb_pwdata_reg_next;
    assign M_APB_PWSTRB = m_apb_pwstrb_reg_next;
    assign M_APB_PPROT = m_apb_pprot_reg_next;

endmodule
