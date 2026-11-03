module apbslave #(
        parameter   C_APB_ADDR_WIDTH = 12,
        parameter   C_APB_DATA_WIDTH = 32,
        localparam  AW = C_APB_ADDR_WIDTH,
        localparam  DW = C_APB_DATA_WIDTH,
        localparam  APBLSB = $clog2(C_APB_DATA_WIDTH)-3
    ) (
        input   wire            PCLK, PRESETn,
        input   wire            PSEL,
        input   wire            PENABLE,
        output  reg             PREADY,
        input   wire  [AW-1:0]  PADDR,
        input   wire            PWRITE,
        input   wire  [DW-1:0]  PWDATA,
        input   wire  [DW/8-1:0] PWSTRB,
        input   wire  [2:0]     PPROT,
        output  reg   [DW-1:0]  PRDATA,
        output  wire            PSLVERR
    );

    // Internal signals
    reg [DW-1:0]  memory [0:(1<<AW)-1];
    reg [DW-1:0]  read_data;
    reg [DW-1:0]  write_data;
    reg [DW/8-1:0] write_strobe;
    reg [AW-1:0]  address;
    reg           write_enable;

    // Reset and state handling
    always @(posedge PCLK or negedge PRESETn) begin
        if (~PRESETn) begin
            PREADY <= 0;
            PRDATA <= 0;
            PSLVERR <= 0;
        end else begin
            PREADY <= 0;
            PSLVERR <= 0;

            if (PSEL) begin
                if (PENABLE) begin
                    address <= PADDR;
                    write_data <= PWDATA;
                    write_strobe <= PWSTRB;
                    write_enable <= PWRITE;

                    if (PWRITE) begin
                        // Byte-strobed write operation
                        PREADY <= 1;
                        integer i;
                        for (i = 0; i < DW/8; i = i + 1) begin
                            if (PWSTRB[i]) begin
                                memory[address][i*8 +: 8] <= PWDATA[i*8 +: 8];
                            end
                        end
                    end else begin
                        // Read operation
                        PREADY <= 1;
                        read_data <= memory[address];
                        PRDATA <= read_data;
                    end
                end
            end
        end
    end

endmodule
