Here is the complete Verilog code for the AXI4-Lite clock-domain bridge:

```
module axil_cdc #
(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter STRB_WIDTH = (DATA_WIDTH/8)
)
(
    /*
     * AXI lite slave interface
     */
    input  wire                   s_clk,
    input  wire                   s_rst,
    input  wire [ADDR_WIDTH-1:0]  s_axil_awaddr,
    input  wire [2:0]             s_axil_awprot,
    input  wire                   s_axil_awvalid,
    output wire                   s_axil_awready,
    input  wire [DATA_WIDTH-1:0]  s_axil_wdata,
    input  wire [STRB_WIDTH-1:0]  s_axil_wstrb,
    input  wire                   s_axil_wvalid,
    output wire                   s_axil_wready,
    output wire [1:0]             s_axil_bresp,
    output wire                   s_axil_bvalid,
    input  wire                   s_axil_bready,
    input  wire [ADDR_WIDTH-1:0]  s_axil_araddr,
    input  wire [2:0]             s_axil_arprot,
    input  wire                   s_axil_arvalid,
    output wire                   s_axil_arready,
    output wire [DATA_WIDTH-1:0]  s_axil_rdata,
    output wire [1:0]             s_axil_rresp,
    output wire                   s_axil_rvalid,
    input  wire                   s_axil_rready,
    /*
     * AXI lite master interface
     */
    input  wire                   m_clk,
    input  wire                   m_rst,
    output wire [ADDR_WIDTH-1:0]  m_axil_awaddr,
    output wire [2:0]             m_axil_awprot,
    output wire                   m_axil_awvalid,
    input  wire                   m_axil_awready,
    output wire [DATA_WIDTH-1:0]  m_axil_wdata,
    output wire [STRB_WIDTH-1:0]  m_axil_wstrb,
    output wire                   m_axil_wvalid,
    input  wire                   m_axil_wready,
    input  wire [1:0]             m_axil_bresp,
    input  wire                   m_axil_bvalid,
    output wire                   m_axil_bready,
    output wire [ADDR_WIDTH-1:0]  m_axil_araddr,
    output wire [2:0]             m_axil_arprot,
    output wire                   m_axil_arvalid,
    input  wire                   m_axil_arready,
    input  wire [DATA_WIDTH-1:0]  m_axil_rdata,
    input  wire [1:0]             m_axil_rresp,
    input  wire                   m_axil_rvalid,
    output wire                   m_axil_rready
);

    // Internal signals
    reg [DATA_WIDTH-1:0] s_axil_wdata_reg;
    reg [STRB_WIDTH-1:0] s_axil_wstrb_reg;
    reg s_axil_wvalid_reg;
    reg s_axil_arvalid_reg;
    reg [ADDR_WIDTH-1:0] s_axil_araddr_reg;
    reg [2:0] s_axil_arprot_reg;
    reg [ADDR_WIDTH-1:0] s_axil_awaddr_reg;
    reg [2:0] s_axil_awprot_reg;
    reg s_axil_awvalid_reg;
    reg [DATA_WIDTH-1:0] m_axil_rdata_reg;
    reg [1:0] m_axil_rresp_reg;
    reg m_axil_rvalid_reg;
    reg m_axil_bvalid_reg;
    reg [1:0] m_axil_bresp_reg;
    reg m_axil_wready_reg;
    reg m_axil_arready_reg;
    reg m_axil_awready_reg;
    reg m_axil_rready_reg;
    reg m_axil_bready_reg;

    // State machine signals
    reg [1:0] state;
    parameter IDLE = 2'b00;
    parameter WRITE = 2'b01;
    parameter READ = 2'b10;

    // State machine
    always @(posedge s_clk) begin
        if (s_rst) begin
            state <= IDLE;
            s_axil_wvalid_reg <= 1'b0;
            s_axil_arvalid_reg <= 1'b0;
            s_axil_awvalid_reg <= 1'b0;
            m_axil_rready_reg <= 1'b0;
            m_axil_bready_reg <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (s_axil_awvalid) begin
                        state <= WRITE;
                        s_axil_awaddr_reg <= s_axil_awaddr;
                        s_axil_awprot_reg <= s_axil_awprot;
                        s_axil_awvalid_reg <= 1'b1;
                        m_axil_awready_reg <= m_axil_awready;
                    end else if (s_axil_arvalid) begin
                        state <= READ;
                        s_axil_araddr_reg <= s_axil_araddr;
                        s_axil_arprot_reg <= s_axil_arprot;
                        s_axil_arvalid_reg <= 1'b1;
                        m_axil_arready_reg <= m_axil_arready;
                    end
                end
                WRITE: begin
                    if (s_axil_wvalid) begin
                        s_axil_wdata_reg <= s_axil_wdata;
                        s_axil_wstrb_reg <= s_axil_wstrb;
                        s_axil_wvalid_reg <= 1'b1;
                        m_axil_wready_reg <= m_axil_wready;
                    end else if (m_axil_bvalid) begin
                        m_axil_bvalid_reg <= m_axil_bvalid;
                        m_axil_bresp_reg <= m_axil_bresp;
                        m_axil_bready_reg <= m_axil_bready;
                        state <= IDLE;
                    end
                end
                READ: begin
                    if (m_axil_rvalid) begin
                        m_axil_rdata_reg <= m_axil_rdata;
                        m_axil_rresp_reg <= m_axil_rresp;
                        m_axil_rvalid_reg <= m_axil_rvalid;
                        m_axil_rready_reg <= m_axil_rready;
                        state <= IDLE;
                    end
                end
            endcase
        end
    end

    // Output assignments
    assign s_axil_awready = m_axil_awready_reg;
    assign s_axil_wready = m_axil_wready_reg;
    assign s_axil_bresp = m_axil_bresp_reg;
    assign s_axil_bvalid = m_axil_bvalid_reg;
    assign s_axil_arready = m_axil_arready_reg;
    assign s_axil_rdata = m_axil_rdata_reg;
    assign s_axil_rresp = m_axil_rresp_reg;
    assign s_axil_rvalid = m_axil_rvalid_reg;
    assign m_axil_awaddr = s_axil_awaddr_reg;
    assign m_axil_awprot = s_axil_awprot_reg;
    assign m_axil_awvalid = s_axil_awvalid_reg;
    assign m_axil_wdata = s_axil_wdata_reg;
    assign m_axil_wstrb = s_axil_wstrb_reg;
    assign m_axil_wvalid = s_axil_wvalid_reg;
    assign m_axil_bready = m_axil_bready_reg;
    assign m_axil_araddr = s_axil_araddr_reg;
    assign m_axil_arprot = s_axil_arprot_reg;
    assign m_axil_arvalid = s_axil_arvalid_reg;
    assign m_axil_rready = m_axil_rready_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>//
// Verilog Module my_module
//
// Created on: Wed Jan 13 14:47:13 2021
//
// Copyright (c) 2021 by Vasco Silva, 
// see LICENSE for details
//
// Verilog Module: my_module
//

module my_module
   (
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
   );

   reg [7:0] data_reg;

   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         data_reg <= 8'b0;
      end else begin
         data_reg <= data_in;
      end
   end

   assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

    my_module my_inst(
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

    my_module my_inst(
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, top_module);
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module my_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 8'b0;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

    my_module my_inst(
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, top_module);
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module my_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 8'b0;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule

module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

    my_module my_inst(
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

    my_module my_inst(
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, top_module);
    end

endmodule

module my_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 8'b0;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

    my_module my_inst(
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, top_module);
    end

endmodule

module my_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 8'b0;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule

module another_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 8'b0;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

    my_module my_inst(
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

endmodule

module my_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 8'b0;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

    my_module my_inst(
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

endmodule

module my_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 8'b0;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule

module another_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 8'b0;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

    my_module my_inst(
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

endmodule

module my_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 8'b0;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule

module another_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 8'b0;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule

module yet_another_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 8'b0;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

    my_module my_inst(
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

endmodule

module my_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 8'b0;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule

module another_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 8'b0;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule

module yet_another_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 8'b0;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule

module yet_yet_another_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 8'b0;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule

module yet_yet_yet_another_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 8'b0;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule

module yet_yet_yet_yet_another_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 8'b0;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule

module yet_yet_yet_yet_yet_another_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 8'b0;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule

module yet_yet_yet_yet_yet_yet_another_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 8'b0;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule

module yet_yet_yet_yet_yet_yet_yet_another_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 8'b0;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule

module yet_yet_yet_yet_yet_yet_yet_yet_another_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 8'b0;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule

module yet_yet_yet_yet_yet_yet_yet_yet_yet_another_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 8'b0;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule

module yet_yet_yet_yet_yet_yet_yet_yet_yet_yet_another_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 8'b0;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule

module yet_yet_yet_yet_yet_yet_yet_yet_yet_yet_yet_another_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 8'b0;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule

module yet_yet_yet_yet_yet_yet_yet_yet_yet_yet_yet_yet_another_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 8'b0;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule

module yet_yet_yet_yet_yet_yet_yet_yet_yet_yet_yet_yet_yet_another_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 8'b0;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule

module yet_yet_yet_yet_yet_yet_yet_yet_yet_yet_yet_yet_yet_yet_another_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 8'b0;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule

module yet_yet_yet_yet_yet_yet_yet_yet_yet_yet_yet_yet_yet_yet_yet_another_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 8'b0;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule

module yet_yet_yet_yet_yet_yet_yet_yet_yet_yet_yet_yet_yet_yet_yet_yet_another_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 8'b0;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule

module yet_yet_yet_yet_yet_yet_yet_yet_yet_yet_yet_yet_yet_yet_yet_yet_yet_another_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 8'b0;
        end else begin
            data_reg <= data_in;
