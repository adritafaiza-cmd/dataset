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

    wire sync_out;

    sync_chain #(
        .STAGES(STAGES)
    ) sync_chain_inst (
        .clk_i    (clk_i),
        .rst_ni   (rst_ni),
        .async_in (serial_i),
        .sync_out (sync_out)
    );

    edge_detector edge_detector_inst (
        .clk_i    (clk_i),
        .rst_ni   (rst_ni),
        .signal_in(sync_out),
        .en_i     (en_i),
        .r_edge_o (r_edge_o),
        .f_edge_o (f_edge_o)
    );

    assign serial_o = sync_out;

endmodule

module sync_chain #(
    parameter STAGES = 2
)(
    input  clk_i,
    input  rst_ni,
    input  async_in,
    output sync_out
);

    reg [STAGES-1:0] sync_chain;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_chain <= {STAGES{1'b0}};
        end else begin
            sync_chain <= {sync_chain[STAGES-2:0], async_in};
        end
    end

    assign sync_out = sync_chain[STAGES-1];

endmodule

module edge_detector (
    input  clk_i,
    input  rst_ni,
    input  signal_in,
    input  en_i,
    output r_edge_o,
    output f_edge_o
);

    reg  signal_d1;
    reg  signal_d2;
    wire signal_rising;
    wire signal_falling;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            signal_d1 <= 1'b0;
            signal_d2 <= 1'b0;
        end else begin
            signal_d1 <= signal_in;
            signal_d2 <= signal_d1;
        end
    end

    assign signal_rising  = signal_d1 & ~signal_d2;
    assign signal_falling = ~signal_d1 & signal_d2;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            r_edge_o <= 1'b0;
            f_edge_o <= 1'b0;
        end else begin
            r_edge_o <= en_i & signal_rising;
            f_edge_o <= en_i & signal_falling;
        end
    end

endmodule
