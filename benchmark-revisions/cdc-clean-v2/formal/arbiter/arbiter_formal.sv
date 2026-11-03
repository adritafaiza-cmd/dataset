module arbiter_formal;
  localparam PORTS=4;
  reg clk;
  initial clk=0;
  always @($global_clock) clk<=~clk;

  (* anyseq *) reg rst;
  (* anyseq *) reg [PORTS-1:0] request, acknowledge;
  wire [PORTS-1:0] rr_grant, fixed_grant, block_grant;
  wire rr_valid, fixed_valid, block_valid;
  wire [1:0] rr_encoded, fixed_encoded, block_encoded;

  arbiter #(.PORTS(PORTS), .ARB_TYPE_ROUND_ROBIN(1), .ARB_BLOCK(0),
    .ARB_LSB_HIGH_PRIORITY(0)) rr (
    .clk(clk), .rst(rst), .request(request), .acknowledge(acknowledge),
    .grant(rr_grant), .grant_valid(rr_valid), .grant_encoded(rr_encoded));
  arbiter #(.PORTS(PORTS), .ARB_TYPE_ROUND_ROBIN(0), .ARB_BLOCK(0),
    .ARB_LSB_HIGH_PRIORITY(1)) fixed_lsb (
    .clk(clk), .rst(rst), .request(request), .acknowledge(acknowledge),
    .grant(fixed_grant), .grant_valid(fixed_valid), .grant_encoded(fixed_encoded));
  arbiter #(.PORTS(PORTS), .ARB_TYPE_ROUND_ROBIN(1), .ARB_BLOCK(1),
    .ARB_BLOCK_ACK(1), .ARB_LSB_HIGH_PRIORITY(0)) block_ack (
    .clk(clk), .rst(rst), .request(request), .acknowledge(acknowledge),
    .grant(block_grant), .grant_valid(block_valid), .grant_encoded(block_encoded));

  reg past_valid, previous_reset;
  reg [PORTS-1:0] previous_request, previous_ack;
  reg [PORTS-1:0] previous_block_grant;
  reg previous_block_valid;
  reg [PORTS-1:0] fairness_seen;
  reg [2:0] fairness_age;
  initial begin
    past_valid=0; previous_reset=1; previous_request=0; previous_ack=0;
    previous_block_grant=0; previous_block_valid=0;
    fairness_seen=0; fairness_age=0; assume(rst);
  end

  function automatic onehot0(input [PORTS-1:0] value);
    onehot0 = value==0 || ((value & (value-1'b1))==0);
  endfunction

  always @(posedge clk) begin
    past_valid<=1;
    previous_reset<=rst;
    previous_request<=request;
    previous_ack<=acknowledge;
    previous_block_grant<=block_grant;
    previous_block_valid<=block_valid;

    if (past_valid && previous_reset) begin
      assert(!rr_valid && rr_grant==0 && rr_encoded==0);
      assert(!fixed_valid && fixed_grant==0 && fixed_encoded==0);
      assert(!block_valid && block_grant==0 && block_encoded==0);
    end
    if (past_valid && !previous_reset) begin
      assert(onehot0(rr_grant));
      assert(onehot0(fixed_grant));
      assert(onehot0(block_grant));
      assert(rr_valid==(rr_grant!=0));
      assert(fixed_valid==(fixed_grant!=0));
      assert(block_valid==(block_grant!=0));
      if (rr_valid) begin
        assert((rr_grant & previous_request)!=0);
        assert(rr_grant==(4'b0001 << rr_encoded));
      end
      if (fixed_valid) begin
        assert((fixed_grant & previous_request)!=0);
        assert(fixed_grant==(4'b0001 << fixed_encoded));
        // This instance is fixed, LSB-high priority.
        assert((fixed_grant & (fixed_grant-1'b1))==0);
        assert((previous_request & (fixed_grant-1'b1))==0);
      end
      if (block_valid)
        assert(block_grant==(4'b0001 << block_encoded));

      // Once the blocking instance has an unacknowledged grant, it is stable.
      if (previous_block_valid &&
          !(previous_block_grant & previous_ack) && !rst) begin
        assert(block_valid);
        assert(block_grant==previous_block_grant);
      end
    end

    // With all requests persistent, round-robin must serve all four ports
    // within four registered grants.  This is bounded progress, not an
    // unconstrained temporal fairness claim.
    if (rst || request!=4'b1111) begin
      fairness_seen<=0;
      fairness_age<=0;
    end else if (rr_valid) begin
      fairness_seen<=fairness_seen | rr_grant;
      if (fairness_age==3) begin
        assert((fairness_seen | rr_grant)==4'b1111);
        fairness_seen<=0;
        fairness_age<=0;
      end else fairness_age<=fairness_age+1'b1;
    end

    cover(!rst && fairness_seen==4'b1110 && rr_grant==4'b0001);
    cover(!rst && block_valid && !(block_grant & acknowledge));
  end
endmodule
