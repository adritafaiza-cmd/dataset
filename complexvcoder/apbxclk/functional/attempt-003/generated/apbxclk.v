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

    wire [AW-1:0] src2dst_S_APB_PADDR;
    wire src2dst_S_APB_PWRITE;
    wire [DW-1:0] src2dst_S_APB_PWDATA;
    wire [DW/8-1:0] src2dst_S_APB_PWSTRB;
    wire [2:0] src2dst_S_APB_PPROT;
    wire src2dst_S_APB_PSEL;
    wire src2dst_S_APB_PENABLE;
    wire src2dst_D_APB_PREADY;
    wire [DW-1:0] src2dst_D_APB_PRDATA;
    wire src2dst_D_APB_PSLVERR;

    wire [AW-1:0] dst2src_S_APB_PADDR;
    wire dst2src_S_APB_PWRITE;
    wire [DW-1:0] dst2src_S_APB_PWDATA;
    wire [DW/8-1:0] dst2src_S_APB_PWSTRB;
    wire [2:0] dst2src_S_APB_PPROT;
    wire dst2src_S_APB_PSEL;
    wire dst2src_S_APB_PENABLE;
    wire dst2src_D_APB_PREADY;
    wire [DW-1:0] dst2src_D_APB_PRDATA;
    wire dst2src_D_APB_PSLVERR;

    reg src2dst_ready;
    reg [DW-1:0] src2dst_data;
    reg src2dst_error;

    reg dst2src_ready;
    reg [DW-1:0] dst2src_data;
    reg dst2src_error;

    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            S_APB_PREADY <= 0;
            src2dst_ready <= 0;
            src2dst_data <= 0;
            src2dst_error <= 0;
        end else begin
            if (S_APB_PSEL && S_APB_PENABLE) begin
                src2dst_S_APB_PADDR <= S_APB_PADDR;
                src2dst_S_APB_PWRITE <= S_APB_PWRITE;
                src2dst_S_APB_PWDATA <= S_APB_PWDATA;
                src2dst_S_APB_PWSTRB <= S_APB_PWSTRB;
                src2dst_S_APB_PPROT <= S_APB_PPROT;
                src2dst_S_APB_PSEL <= 1;
                src2dst_S_APB_PENABLE <= 1;
                src2dst_ready <= 0;
                src2dst_data <= 0;
                src2dst_error <= 0;
            end else begin
                src2dst_S_APB_PSEL <= 0;
                src2dst_S_APB_PENABLE <= 0;
            end

            if (src2dst_D_APB_PREADY) begin
                src2dst_ready <= 1;
                src2dst_data <= src2dst_D_APB_PRDATA;
                src2dst_error <= src2dst_D_APB_PSLVERR;
            end

            if (src2dst_ready && M_APB_PREADY) begin
                S_APB_PREADY <= 1;
                S_APB_PRDATA <= src2dst_data;
                S_APB_PSLVERR <= src2dst_error;
            end else begin
                S_APB_PREADY <= 0;
            end
        end
    end

    always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            M_PRESETn <= 1;
            M_APB_PSEL <= 0;
            M_APB_PENABLE <= 0;
            dst2src_ready <= 0;
            dst2src_data <= 0;
            dst2src_error <= 0;
        end else begin
            if (M_APB_PSEL && M_APB_PENABLE) begin
                dst2src_S_APB_PADDR <= M_APB_PADDR;
                dst2src_S_APB_PWRITE <= M_APB_PWRITE;
                dst2src_S_APB_PWDATA <= M_APB_PWDATA;
                dst2src_S_APB_PWSTRB <= M_APB_PWSTRB;
                dst2src_S_APB_PPROT <= M_APB_PPROT;
                dst2src_S_APB_PSEL <= 1;
                dst2src_S_APB_PENABLE <= 1;
                dst2src_ready <= 0;
                dst2src_data <= 0;
                dst2src_error <= 0;
            end else begin
                dst2src_S_APB_PSEL <= 0;
                dst2src_S_APB_PENABLE <= 0;
            end

            if (dst2src_D_APB_PREADY) begin
                dst2src_ready <= 1;
                dst2src_data <= dst2src_D_APB_PRDATA;
                dst2src_error <= dst2src_D_APB_PSLVERR;
            end

            if (dst2src_ready && src2dst_D_APB_PREADY) begin
                M_APB_PREADY <= 1;
                M_APB_PADDR <= dst2src_S_APB_PADDR;
                M_APB_PWRITE <= dst2src_S_APB_PWRITE;
                M_APB_PWDATA <= dst2src_S_APB_PWDATA;
                M_APB_PWSTRB <= dst2src_S_APB_PWSTRB;
                M_APB_PPROT <= dst2src_S_APB_PPROT;
                M_APB_PSEL <= 1;
                M_APB_PENABLE <= 1;
                M_APB_PDATA <= dst2src_data;
                M_APB_PSLVERR <= dst2src_error;
            end else begin
                M_APB_PREADY <= 0;
            end
        end
    end

endmodule
