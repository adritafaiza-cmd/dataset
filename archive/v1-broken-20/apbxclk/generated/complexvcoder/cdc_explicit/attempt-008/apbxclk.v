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

    wire [AW-1:0] apb_master_crossing_to_slave_crossing;
    wire [DW-1:0] apb_slave_crossing_to_master_crossing;

    apb_master_crossing #(
        .C_APB_ADDR_WIDTH(C_APB_ADDR_WIDTH),
        .C_APB_DATA_WIDTH(C_APB_DATA_WIDTH),
        .OPT_REGISTERED(OPT_REGISTERED)
    ) apb_master_crossing_inst (
        .S_APB_PCLK(S_APB_PCLK),
        .S_PRESETn(S_PRESETn),
        .M_APB_PCLK(M_APB_PCLK),
        .M_APB_PREADY(M_APB_PREADY),
        .M_APB_PSEL(M_APB_PSEL),
        .M_APB_PENABLE(M_APB_PENABLE),
        .M_APB_PADDR(M_APB_PADDR),
        .M_APB_PWRITE(M_APB_PWRITE),
        .M_APB_PWDATA(M_APB_PWDATA),
        .M_APB_PWSTRB(M_APB_PWSTRB),
        .M_APB_PPROT(M_APB_PPROT),
        .M_APB_PRDATA(M_APB_PRDATA),
        .M_APB_PSLVERR(M_APB_PSLVERR),
        .M_PRESETn(M_PRESETn),
        .apb_master_crossing_to_slave_crossing(apb_master_crossing_to_slave_crossing)
    );

    apb_slave_crossing #(
        .C_APB_ADDR_WIDTH(C_APB_ADDR_WIDTH),
        .C_APB_DATA_WIDTH(C_APB_DATA_WIDTH),
        .OPT_REGISTERED(OPT_REGISTERED)
    ) apb_slave_crossing_inst (
        .S_APB_PCLK(S_APB_PCLK),
        .S_PRESETn(S_PRESETn),
        .S_APB_PSEL(S_APB_PSEL),
        .S_APB_PENABLE(S_APB_PENABLE),
        .S_APB_PREADY(S_APB_PREADY),
        .S_APB_PADDR(S_APB_PADDR),
        .S_APB_PWRITE(S_APB_PWRITE),
        .S_APB_PWDATA(S_APB_PWDATA),
        .S_APB_PWSTRB(S_APB_PWSTRB),
        .S_APB_PPROT(S_APB_PPROT),
        .S_APB_PRDATA(apb_slave_crossing_to_master_crossing),
        .S_APB_PSLVERR(apb_slave_crossing_to_master_crossing),
        .M_APB_PCLK(M_APB_PCLK),
        .apb_slave_crossing_to_master_crossing(apb_slave_crossing_to_master_crossing)
    );

endmodule

module apb_master_crossing #(
    parameter C_APB_ADDR_WIDTH = 12,
    parameter C_APB_DATA_WIDTH = 32,
    parameter [0:0] OPT_REGISTERED = 1'b0
) (
    input wire S_APB_PCLK,
    input wire S_PRESETn,
    input wire M_APB_PCLK,
    input wire M_APB_PREADY,
    input wire M_APB_PSEL,
    input wire M_APB_PENABLE,
    input wire [C_APB_ADDR_WIDTH-1:0] M_APB_PADDR,
    input wire M_APB_PWRITE,
    input wire [C_APB_DATA_WIDTH-1:0] M_APB_PWDATA,
    input wire [C_APB_DATA_WIDTH/8-1:0] M_APB_PWSTRB,
    input wire [2:0] M_APB_PPROT,
    output wire [C_APB_DATA_WIDTH-1:0] M_APB_PRDATA,
    output wire M_APB_PSLVERR,
    output reg M_PRESETn,
    output reg [C_APB_ADDR_WIDTH-1:0] apb_master_crossing_to_slave_crossing
);

    reg [C_APB_ADDR_WIDTH-1:0] paddr;
    reg pwrite;
    reg [C_APB_DATA_WIDTH-1:0] pwdata;
    reg [C_APB_DATA_WIDTH/8-1:0] pwstrb;
    reg [2:0] pprot;
    reg penable;
    reg psel;
    wire pready;
    wire [C_APB_DATA_WIDTH-1:0] prdata;
    wire pslverr;

    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            paddr <= 0;
            pwrite <= 0;
            pwdata <= 0;
            pwstrb <= 0;
            pprot <= 0;
            penable <= 0;
            psel <= 0;
            apb_master_crossing_to_slave_crossing <= 0;
        end else begin
            paddr <= S_APB_PADDR;
            pwrite <= S_APB_PWRITE;
            pwdata <= S_APB_PWDATA;
            pwstrb <= S_APB_PWSTRB;
            pprot <= S_APB_PPROT;
            penable <= S_APB_PENABLE;
            psel <= S_APB_PSEL;
            apb_master_crossing_to_slave_crossing <= pwdata;
        end
    end

    apb_slave #(
        .C_APB_ADDR_WIDTH(C_APB_ADDR_WIDTH),
        .C_APB_DATA_WIDTH(C_APB_DATA_WIDTH)
    ) apb_slave_inst (
        .PCLK(S_APB_PCLK),
        .PRESETn(S_PRESETn),
        .PSEL(psel),
        .PENABLE(penable),
        .PREADY(pready),
        .PADDR(paddr),
        .PWRITE(pwrite),
        .PWDATA(pwdata),
        .PWSTRB(pwstrb),
        .PPROT(pprot),
        .PRDATA(prdata),
        .PSLVERR(pslverr)
    );

endmodule

module apb_slave_crossing #(
    parameter C_APB_ADDR_WIDTH = 12,
    parameter C_APB_DATA_WIDTH = 32,
    parameter [0:0] OPT_REGISTERED = 1'b0
) (
    input wire S_APB_PCLK,
    input wire S_PRESETn,
    input wire S_APB_PSEL,
    input wire S_APB_PENABLE,
    input wire S_APB_PREADY,
    input wire [C_APB_ADDR_WIDTH-1:0] S_APB_PADDR,
    input wire S_APB_PWRITE,
    input wire [C_APB_DATA_WIDTH-1:0] S_APB_PWDATA,
    input wire [C_APB_DATA_WIDTH/8-1:0] S_APB_PWSTRB,
    input wire [2:0] S_APB_PPROT,
    output wire [C_APB_DATA_WIDTH-1:0] S_APB_PRDATA,
    output wire S_APB_PSLVERR,
    input wire M_APB_PCLK,
    output reg [C_APB_DATA_WIDTH-1:0] apb_slave_crossing_to_master_crossing
);

    reg [C_APB_ADDR_WIDTH-1:0] paddr;
    reg pwrite;
    reg [C_APB_DATA_WIDTH-1:0] pwdata;
    reg [C_APB_DATA_WIDTH/8-1:0] pwstrb;
    reg [2:0] pprot;
    reg penable;
    reg psel;
    wire pready;
    wire [C_APB_DATA_WIDTH-1:0] prdata;
    wire pslverr;

    always @(posedge M_APB_PCLK) begin
        if (S_APB_PSEL && S_APB_PENABLE && !S_APB_PREADY) begin
            paddr <= S_APB_PADDR;
            pwrite <= S_APB_PWRITE;
            pwdata <= S_APB_PWDATA;
            pwstrb <= S_APB_PWSTRB;
            pprot <= S_APB_PPROT;
            penable <= 1;
            psel <= 1;
        end else begin
            penable <= 0;
            psel <= 0;
        end
    end

    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            apb_slave_crossing_to_master_crossing <= 0;
        end else begin
            apb_slave_crossing_to_master_crossing <= prdata;
        end
    end

    apb_master #(
        .C_APB_ADDR_WIDTH(C_APB_ADDR_WIDTH),
        .C_APB_DATA_WIDTH(C_APB_DATA_WIDTH)
    ) apb_master_inst (
        .PCLK(M_APB_PCLK),
        .PRESETn(M_PRESETn),
        .PSEL(psel),
        .PENABLE(penable),
        .PREADY(pready),
        .PADDR(paddr),
        .PWRITE(pwrite),
        .PWDATA(pwdata),
        .PWSTRB(pwstrb),
        .PPROT(pprot),
        .PRDATA(prdata),
        .PSLVERR(pslverr)
    );

endmodule

module apb_slave #(
    parameter C_APB_ADDR_WIDTH = 12,
    parameter C_APB_DATA_WIDTH = 32
) (
    input wire PCLK,
    input wire PRESETn,
    input wire PSEL,
    input wire PENABLE,
    output wire PREADY,
    output wire [C_APB_ADDR_WIDTH-1:0] PADDR,
    output wire PWRITE,
    output wire [C_APB_DATA_WIDTH-1:0] PWDATA,
    output wire [C_APB_DATA_WIDTH/8-1:0] PWSTRB,
    output wire [2:0] PPROT,
    input wire [C_APB_DATA_WIDTH-1:0] PRDATA,
    input wire PSLVERR
);

    reg [C_APB_ADDR_WIDTH-1:0] paddr;
    reg pwrite;
    reg [C_APB_DATA_WIDTH-1:0] pwdata;
    reg [C_APB_DATA_WIDTH/8-1:0] pwstrb;
    reg [2:0] pprot;
    reg penable;
    reg psel;
    wire pready;
    wire [C_APB_DATA_WIDTH-1:0] prdata;
    wire pslverr;

    assign PADDR = paddr;
    assign PWRITE = pwrite;
    assign PWDATA = pwdata;
    assign PWSTRB = pwstrb;
    assign PPROT = pprot;
    assign PREADY = pready;
    assign PRDATA = prdata;
    assign PSLVERR = pslverr;

endmodule

module apb_master #(
    parameter C_APB_ADDR_WIDTH = 12,
    parameter C_APB_DATA_WIDTH = 32
) (
    input wire PCLK,
    input wire PRESETn,
    input wire PSEL,
    input wire PENABLE,
    output wire PREADY,
    output wire [C_APB_ADDR_WIDTH-1:0] PADDR,
    output wire PWRITE,
    output wire [C_APB_DATA_WIDTH-1:0] PWDATA,
    output wire [C_APB_DATA_WIDTH/8-1:0] PWSTRB,
    output wire [2:0] PPROT,
    input wire [C_APB_DATA_WIDTH-1:0] PRDATA,
    input wire PSLVERR
);

    reg [C_APB_ADDR_WIDTH-1:0] paddr;
    reg pwrite;
    reg [C_APB_DATA_WIDTH-1:0] pwdata;
    reg [C_APB_DATA_WIDTH/8-1:0] pwstrb;
    reg [2:0] pprot;
    reg penable;
    reg psel;
    wire pready;
    wire [C_APB_DATA_WIDTH-1:0] prdata;
    wire pslverr;

    assign PADDR = paddr;
    assign PWRITE = pwrite;
    assign PWDATA = pwdata;
    assign PWSTRB = pwstrb;
    assign PPROT = pprot;
    assign PREADY = pready;
    assign PRDATA = prdata;
    assign PSLVERR = pslverr;

endmodule
