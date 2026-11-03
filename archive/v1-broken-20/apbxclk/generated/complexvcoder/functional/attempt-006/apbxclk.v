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

    reg [AW-1:0] req_addr;
    reg req_write;
    reg [DW-1:0] req_wdata;
    reg [DW/8-1:0] req_wstrb;
    reg [2:0] req_prot;
    reg req_valid;
    wire req_ready;
    wire resp_valid;
    reg resp_ready;
    wire [DW-1:0] resp_rdata;
    wire resp_slverr;

    // Register the signals if OPT_REGISTERED is set
    generate
        if (OPT_REGISTERED) begin : registered_crossing
            reg [AW-1:0] reg_req_addr;
            reg reg_req_write;
            reg [DW-1:0] reg_req_wdata;
            reg [DW/8-1:0] reg_req_wstrb;
            reg [2:0] reg_req_prot;
            reg reg_req_valid;
            wire reg_req_ready;
            wire reg_resp_valid;
            reg reg_resp_ready;
            wire [DW-1:0] reg_resp_rdata;
            wire reg_resp_slverr;

            assign reg_req_addr = req_addr;
            assign reg_req_write = req_write;
            assign reg_req_wdata = req_wdata;
            assign reg_req_wstrb = req_wstrb;
            assign reg_req_prot = req_prot;
            assign reg_req_valid = req_valid;
            assign req_ready = reg_req_ready;
            assign resp_valid = reg_resp_valid;
            assign reg_resp_ready = resp_ready;
            assign reg_resp_rdata = resp_rdata;
            assign reg_resp_slverr = resp_slverr;
        end else begin : unregistered_crossing
            assign reg_req_addr = req_addr;
            assign reg_req_write = req_write;
            assign reg_req_wdata = req_wdata;
            assign reg_req_wstrb = req_wstrb;
            assign reg_req_prot = req_prot;
            assign reg_req_valid = req_valid;
            assign req_ready = 1'b1;
            assign resp_valid = 1'b1;
            assign reg_resp_ready = resp_ready;
            assign reg_resp_rdata = resp_rdata;
            assign reg_resp_slverr = resp_slverr;
        end
    endgenerate

    // Bridge logic
    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            req_valid <= 1'b0;
            S_APB_PREADY <= 1'b0;
        end else begin
            if (S_APB_PSEL && S_APB_PENABLE && !S_APB_PREADY) begin
                req_addr <= S_APB_PADDR;
                req_write <= S_APB_PWRITE;
                req_wdata <= S_APB_PWDATA;
                req_wstrb <= S_APB_PWSTRB;
                req_prot <= S_APB_PPROT;
                req_valid <= 1'b1;
            end
            if (req_valid && req_ready) begin
                S_APB_PREADY <= 1'b1;
            end else begin
                S_APB_PREADY <= 1'b0;
            end
        end
    end

    always @(posedge M_APB_PCLK) begin
        if (M_APB_PREADY) begin
            resp_valid <= 1'b1;
            resp_ready <= 1'b0;
        end else begin
            resp_valid <= 1'b0;
            resp_ready <= 1'b1;
        end
    end

    // Connect to the bridge module
    apbxclk_bridge #(
        .C_APB_ADDR_WIDTH(C_APB_ADDR_WIDTH),
        .C_APB_DATA_WIDTH(C_APB_DATA_WIDTH),
        .OPT_REGISTERED(OPT_REGISTERED)
    ) bridge (
        .S_APB_PCLK(S_APB_PCLK),
        .S_PRESETn(S_PRESETn),
        .S_APB_PSEL(S_APB_PSEL),
        .S_APB_PENABLE(S_APB_PENABLE),
        .S_APB_PREADY(S_APB_PREADY),
        .S_APB_PADDR(req_addr),
        .S_APB_PWRITE(req_write),
        .S_APB_PWDATA(req_wdata),
        .S_APB_PWSTRB(req_wstrb),
        .S_APB_PPROT(req_prot),
        .S_APB_PRDATA(S_APB_PRDATA),
        .S_APB_PSLVERR(S_APB_PSLVERR),
        .M_APB_PCLK(M_APB_PCLK),
        .M_PRESETn(M_PRESETn),
        .M_APB_PSEL(M_APB_PSEL),
        .M_APB_PENABLE(M_APB_PENABLE),
        .M_APB_PREADY(M_APB_PREADY),
        .M_APB_PADDR(M_APB_PADDR),
        .M_APB_PWRITE(M_APB_PWRITE),
        .M_APB_PWDATA(M_APB_PWDATA),
        .M_APB_PWSTRB(M_APB_PWSTRB),
        .M_APB_PPROT(M_APB_PPROT),
        .M_APB_PRDATA(M_APB_PRDATA),
        .M_APB_PSLVERR(M_APB_PSLVERR)
    );

endmodule

module apbxclk_bridge #(
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
    input wire [DW/8-1:0] S_APB_PWSTRB,
    input wire [2:0] S_APB_PPROT,
    output reg [DW-1:0] S_APB_PRDATA,
    output reg S_APB_PSLVERR,
    input wire M_APB_PCLK,
    output reg M_PRESETn,
    output reg M_APB_PSEL,
    output reg M_APB_PENABLE,
    input wire M_APB_PREADY,
    output reg [AW-1:0] M_APB_PADDR,
    output reg M_APB_PWRITE,
    output reg [DW-1:0] M_APB_PWDATA,
    output reg [DW/8-1:0] M_APB_PWSTRB,
    output reg [2:0] M_APB_PPROT,
    input wire [DW-1:0] M_APB_PRDATA,
    input wire M_APB_PSLVERR
);

    reg [AW-1:0] req_addr;
    reg req_write;
    reg [DW-1:0] req_wdata;
    reg [DW/8-1:0] req_wstrb;
    reg [2:0] req_prot;
    reg req_valid;
    wire req_ready;
    wire resp_valid;
    reg resp_ready;
    wire [DW-1:0] resp_rdata;
    wire resp_slverr;

    // Register the signals if OPT_REGISTERED is set
    generate
        if (OPT_REGISTERED) begin : registered_crossing
            reg [AW-1:0] reg_req_addr;
            reg reg_req_write;
            reg [DW-1:0] reg_req_wdata;
            reg [DW/8-1:0] reg_req_wstrb;
            reg [2:0] reg_req_prot;
            reg reg_req_valid;
            wire reg_req_ready;
            wire reg_resp_valid;
            reg reg_resp_ready;
            wire [DW-1:0] reg_resp_rdata;
            wire reg_resp_slverr;

            assign reg_req_addr = req_addr;
            assign reg_req_write = req_write;
            assign reg_req_wdata = req_wdata;
            assign reg_req_wstrb = req_wstrb;
            assign reg_req_prot = req_prot;
            assign reg_req_valid = req_valid;
            assign req_ready = reg_req_ready;
            assign resp_valid = reg_resp_valid;
            assign reg_resp_ready = resp_ready;
            assign reg_resp_rdata = resp_rdata;
            assign reg_resp_slverr = resp_slverr;
        end else begin : unregistered_crossing
            assign reg_req_addr = req_addr;
            assign reg_req_write = req_write;
            assign reg_req_wdata = req_wdata;
            assign reg_req_wstrb = req_wstrb;
            assign reg_req_prot = req_prot;
            assign reg_req_valid = req_valid;
            assign req_ready = 1'b1;
            assign resp_valid = 1'b1;
            assign reg_resp_ready = resp_ready;
            assign reg_resp_rdata = resp_rdata;
            assign reg_resp_slverr = resp_slverr;
        end
    endgenerate

    // Bridge logic
    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            req_valid <= 1'b0;
            S_APB_PREADY <= 1'b0;
        end else begin
            if (S_APB_PSEL && S_APB_PENABLE && !S_APB_PREADY) begin
                req_addr <= S_APB_PADDR;
                req_write <= S_APB_PWRITE;
                req_wdata <= S_APB_PWDATA;
                req_wstrb <= S_APB_PWSTRB;
                req_prot <= S_APB_PPROT;
                req_valid <= 1'b1;
            end
            if (req_valid && req_ready) begin
                S_APB_PREADY <= 1'b1;
            end else begin
                S_APB_PREADY <= 1'b0;
            end
        end
    end

    always @(posedge M_APB_PCLK) begin
        if (M_APB_PREADY) begin
            resp_valid <= 1'b1;
            resp_ready <= 1'b0;
        end else begin
            resp_valid <= 1'b0;
            resp_ready <= 1'b1;
        end
    end

    // Connect to the bridge module
    apbxclk_bridge #(
        .C_APB_ADDR_WIDTH(C_APB_ADDR_WIDTH),
        .C_APB_DATA_WIDTH(C_APB_DATA_WIDTH),
        .OPT_REGISTERED(OPT_REGISTERED)
    ) bridge (
        .S_APB_PCLK(S_APB_PCLK),
        .S_PRESETn(S_PRESETn),
        .S_APB_PSEL(S_APB_PSEL),
        .S_APB_PENABLE(S_APB_PENABLE),
        .S_APB_PREADY(S_APB_PREADY),
        .S_APB_PADDR(req_addr),
        .S_APB_PWRITE(req_write),
        .S_APB_PWDATA(req_wdata),
        .S_APB_PWSTRB(req_wstrb),
        .S_APB_PPROT(req_prot),
        .S_APB_PRDATA(S_APB_PRDATA),
        .S_APB_PSLVERR(S_APB_PSLVERR),
        .M_APB_PCLK(M_APB_PCLK),
        .M_PRESETn(M_PRESETn),
        .M_APB_PSEL(M_APB_PSEL),
        .M_APB_PENABLE(M_APB_PENABLE),
        .M_APB_PREADY(M_APB_PREADY),
        .M_APB_PADDR(M_APB_PADDR),
        .M_APB_PWRITE(M_APB_PWRITE),
        .M_APB_PWDATA(M_APB_PWDATA),
        .M_APB_PWSTRB(M_APB_PWSTRB),
        .M_APB_PPROT(M_APB_PPROT),
        .M_APB_PRDATA(M_APB_PRDATA),
        .M_APB_PSLVERR(M_APB_PSLVERR)
    );

endmodule
