module sync_wedge #(
    parameter STAGES = 2
)(
    input  clk_i,
    input  rst_ni,
    input  en_i,
    input  serial_i,
    output r_edge_o,
    output f_edge_o,
    output serial_o
);

    wire   data_d1;
    wire   data_d2;

    synchronizer #(
        .STAGES(STAGES)
    ) sync_inst (
        .clk_i  (clk_i),
        .rst_ni (rst_ni),
        .data_i (serial_i),
        .data_o (serial_o)
    );

    reg    r_edge_reg;
    reg    f_edge_reg;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            data_d1    <= 1'b0;
            data_d2    <= 1'b0;
            r_edge_reg <= 1'b0;
            f_edge_reg <= 1'b0;
        end else begin
            data_d1    <= serial_o;
            data_d2    <= data_d1;

            if (en_i) begin
                r_edge_reg <= (data_d2 == 1'b0) && (data_d1 == 1'b1);
                f_edge_reg <= (data_d2 == 1'b1) && (data_d1 == 1'b0);
            end else begin
                r_edge_reg <= 1'b0;
                f_edge_reg <= 1'b0;
            end
        end
    end

    assign r_edge_o = r_edge_reg;
    assign f_edge_o = f_edge_reg;

endmodule

module synchronizer #(
    parameter STAGES = 2
)(
    input  clk_i,
    input  rst_ni,
    input  data_i,
    output data_o
);

    reg [STAGES-1:0] sync_reg;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_reg <= {STAGES{1'b0}};
        end else begin
            sync_reg[0] <= data_i;
            for (int i = 1; i < STAGES; i = i + 1) begin
                sync_reg[i] <= sync_reg[i-1];
            end
        end
    end

    assign data_o = sync_reg[STAGES-1];

endmodule
