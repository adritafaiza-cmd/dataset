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
    reg s_apb_pready_reg;
    reg m_apb_psel_reg;
    reg m_apb_penable_reg;
    reg [AW-1:0] m_apb_paddr_reg;
    reg m_apb_pwrite_reg;
    reg [DW-1:0] m_apb_pwdata_reg;
    reg [DW/8-1:0] m_apb_pwstrb_reg;
    reg [2:0] m_apb_pprot_reg;
    reg [DW-1:0] s_apb_prdata_reg;
    reg s_apb_pslverr_reg;
    reg transaction_in_progress;
    reg s_apb_psel_ff;
    reg s_apb_penable_ff;

    // Source clock domain logic
    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            S_APB_PREADY <= 1'b0;
            s_apb_psel_ff <= 1'b0;
            s_apb_penable_ff <= 1'b0;
            transaction_in_progress <= 1'b0;
        end else begin
            // Capture the setup phase
            if (S_APB_PSEL && !S_APB_PENABLE && !transaction_in_progress) begin
                s_apb_psel_ff <= 1'b1;
                transaction_in_progress <= 1'b1;
            end

            // Capture the access phase
            if (S_APB_PSEL && S_APB_PENABLE && transaction_in_progress) begin
                s_apb_penable_ff <= 1'b1;
            end

            // Deassert S_APB_PREADY when transaction is not in progress
            if (!transaction_in_progress) begin
                S_APB_PREADY <= 1'b0;
            end
        end
    end

    // Destination clock domain logic
    always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            M_PRESETn <= 1'b0;
            M_APB_PSEL <= 1'b0;
            M_APB_PENABLE <= 1'b0;
            m_apb_paddr_reg <= {AW{1'b0}};
            m_apb_pwrite_reg <= 1'b0;
            m_apb_pwdata_reg <= {DW{1'b0}};
            m_apb_pwstrb_reg <= {DW/8{1'b0}};
            m_apb_pprot_reg <= 3'b0;
            s_apb_prdata_reg <= {DW{1'b0}};
            s_apb_pslverr_reg <= 1'b0;
        end else begin
            M_PRESETn <= 1'b1;

            // Forward the transaction to the destination
            if (transaction_in_progress && !m_apb_psel_reg) begin
                m_apb_psel_reg <= 1'b1;
                m_apb_paddr_reg <= S_APB_PADDR;
                m_apb_pwrite_reg <= S_APB_PWRITE;
                m_apb_pwdata_reg <= S_APB_PWDATA;
                m_apb_pwstrb_reg <= S_APB_PWSTRB;
                m_apb_pprot_reg <= S_APB_PPROT;
            end

            // Forward the access phase
            if (m_apb_psel_reg && !m_apb_penable_reg) begin
                m_apb_penable_reg <= 1'b1;
            end

            // Capture response from the destination
            if (M_APB_PREADY && m_apb_penable_reg) begin
                s_apb_prdata_reg <= M_APB_PRDATA;
                s_apb_pslverr_reg <= M_APB_PSLVERR;
                m_apb_psel_reg <= 1'b0;
                m_apb_penable_reg <= 1'b0;
                transaction_in_progress <= 1'b0;
                S_APB_PREADY <= 1'b1;
            end
        end
    end

    // Assign outputs
    assign S_APB_PRDATA = OPT_REGISTERED ? s_apb_prdata_reg : M_APB_PRDATA;
    assign S_APB_PSLVERR = OPT_REGISTERED ? s_apb_pslverr_reg : M_APB_PSLVERR;
    assign M_APB_PADDR = OPT_REGISTERED ? m_apb_paddr_reg : S_APB_PADDR;
    assign M_APB_PWRITE = OPT_REGISTERED ? m_apb_pwrite_reg : S_APB_PWRITE;
    assign M_APB_PWDATA = OPT_REGISTERED ? m_apb_pwdata_reg : S_APB_PWDATA;
    assign M_APB_PWSTRB = OPT_REGISTERED ? m_apb_pwstrb_reg : S_APB_PWSTRB;
    assign M_APB_PPROT = OPT_REGISTERED ? m_apb_pprot_reg : S_APB_PPROT;

endmodule
