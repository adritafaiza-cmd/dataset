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
    reg [AW-1:0] s_apb_paddr_sync;
    reg s_apb_pwrite_sync;
    reg [DW-1:0] s_apb_pwdata_sync;
    reg [DW/8-1:0] s_apb_pwstrb_sync;
    reg [2:0] s_apb_pprot_sync;
    reg [DW-1:0] s_apb_prdata_sync;
    reg s_apb_pslverr_sync;
    reg req_valid;
    reg req_ready;
    reg resp_valid;
    reg resp_ready;

    // Source side logic
    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            S_APB_PREADY <= 0;
            req_valid <= 0;
            req_ready <= 0;
        end else begin
            if (req_ready && (S_APB_PSEL && S_APB_PENABLE)) begin
                s_apb_paddr_sync <= S_APB_PADDR;
                s_apb_pwrite_sync <= S_APB_PWRITE;
                s_apb_pwdata_sync <= S_APB_PWDATA;
                s_apb_pwstrb_sync <= S_APB_PWSTRB;
                s_apb_pprot_sync <= S_APB_PPROT;
                req_valid <= 1;
            end else if (resp_valid) begin
                req_valid <= 0;
            end

            if (resp_valid) begin
                S_APB_PREADY <= 1;
                s_apb_prdata_sync <= M_APB_PRDATA;
                s_apb_pslverr_sync <= M_APB_PSLVERR;
                resp_ready <= 1;
            end else begin
                S_APB_PREADY <= 0;
                resp_ready <= 0;
            end
        end
    end

    // Destination side logic
    always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            M_PRESETn <= 0;
            M_APB_PSEL <= 0;
            M_APB_PENABLE <= 0;
            resp_valid <= 0;
        end else begin
            M_PRESETn <= 1;

            if (req_valid && !req_ready) begin
                M_APB_PSEL <= 1;
                M_APB_PENABLE <= 1;
                M_APB_PADDR <= s_apb_paddr_sync;
                M_APB_PWRITE <= s_apb_pwrite_sync;
                M_APB_PWDATA <= s_apb_pwdata_sync;
                M_APB_PWSTRB <= s_apb_pwstrb_sync;
                M_APB_PPROT <= s_apb_pprot_sync;
                req_ready <= 1;
            end else if (M_APB_PREADY) begin
                M_APB_PSEL <= 0;
                M_APB_PENABLE <= 0;
                req_ready <= 0;
                resp_valid <= 1;
            end else begin
                resp_valid <= 0;
            end
        end
    end

    // Assign outputs
    assign S_APB_PRDATA = s_apb_prdata_sync;
    assign S_APB_PSLVERR = s_apb_pslverr_sync;

endmodule
