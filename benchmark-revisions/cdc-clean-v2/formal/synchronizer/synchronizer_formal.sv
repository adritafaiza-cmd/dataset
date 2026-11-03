module synchronizer_formal;
    reg clk;
    (* anyseq *) reg rstn;
    (* anyseq *) reg async_sig_i;

    wire sync_sig_o;

    synchronizer #(.STAGES(2)) dut (
        .clk(clk),
        .rstn(rstn),
        .async_sig_i(async_sig_i),
        .sync_sig_o(sync_sig_o)
    );

    reg [1:0] expected_pipeline;
    reg reset_seen;

    initial begin
        expected_pipeline = 2'b00;
        reset_seen = 1'b0;
        assume(!rstn);
    end

    always @(posedge clk) begin
        if (!rstn) begin
            expected_pipeline <= 2'b00;
            reset_seen <= 1'b1;
        end else if (reset_seen) begin
            expected_pipeline <= {expected_pipeline[0], async_sig_i};
        end

        // Compare only while reset is deasserted. This accepts either
        // synchronous or asynchronous active-low reset implementations.
        if (reset_seen && rstn)
            assert(sync_sig_o == expected_pipeline[1]);

        cover(reset_seen && rstn && sync_sig_o);
    end
endmodule
