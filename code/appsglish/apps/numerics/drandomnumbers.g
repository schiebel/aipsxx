const drandomnumbers := function(pgplotter) {
  public := [=];
  private := [=];
  private.plotter := pgplotter;
  include 'randomnumbers.g'
  private.rand := randomnumbers();

  const public.normal := function(mean, variance) {
    wider private;
    const nsamples := 1E4;
    const data := private.rand.normal(mean, variance, nsamples);
    const minx := as_integer(min(data)) - 1;
    const maxx := as_integer(max(data)) + 1;
    private.plotter.hist(data, minx, maxx, maxx - minx, 0);
    const xvals := seq(minx, maxx, .1);
    const pdf := 1/sqrt(2*pi*variance) * exp(-((xvals - mean)^2/variance/2));
    private.plotter.sci(3);
    private.plotter.line(xvals, nsamples*pdf);
    private.plotter.sci(1);
    private.plotter.lab('', '', 'Normal distribution');
  }

  const public.uniform := function(lower, upper) {
    wider private;
    const nsamples := 1E4;
    const binsperint := 5;
    const data := private.rand.uniform(lower, upper, nsamples);
    const minx := as_integer(min(data)) - 1.5;
    const maxx := as_integer(max(data)) + 1.5;
    private.plotter.hist(data, minx, maxx, (maxx - minx)*binsperint, 0);
    const xvals := seq(minx, maxx, .01);
    const maxpdf := 1/(upper-lower);
    pdf := array(0, length(xvals));
    pdf[xvals >= lower & xvals < upper] := maxpdf;
    private.plotter.sci(3);
    private.plotter.line(xvals, nsamples/binsperint*pdf);
    private.plotter.sci(1);
    private.plotter.lab('', '', 'Uniform distribution');
  }

  const public.discreteuniform := function(lower, upper) {
    wider private;
    const nsamples := 1E4;
    const binsperint := 5;
    const data := private.rand.discreteuniform(lower, upper, nsamples);
    const minx := as_integer(min(data)) - 1 - 0.5/binsperint;
    const maxx := as_integer(max(data)) + 1 + 0.5/binsperint;
    private.plotter.hist(data, minx, maxx, (maxx - minx)*binsperint, 0);
    const xvals := seq(lower-1, upper+1, 1);
    const maxpdf := 1/(upper-lower+1);
    pdf := array(0, length(xvals));
    pdf[xvals >= lower & xvals <= upper] := maxpdf;
    private.plotter.sci(3);
    private.plotter.pt(xvals, nsamples*pdf, 19);
    private.plotter.sci(1);
    private.plotter.lab('', '', 'Discrete uniform distribution');
  }

  const private.factorial := function(n) {
    wider private;
    n[n < 1] := 1;
    if (all(n == 1)) {
      return n;
    } else {
      return n * private.factorial(n-1);
    }
  }

  const public.poisson := function(mean) {
    wider private;
    const nsamples := 1E4;
    const binsperint := 5;
    const data := private.rand.poisson(mean, nsamples);
    const minx := as_integer(min(data)) - 1 - 0.5/binsperint;
    const maxx := as_integer(max(data)) + 1 + 0.5/binsperint;
    private.plotter.hist(data, minx, maxx, (maxx - minx)*binsperint, 0);
    const xvals := seq(-1, max(data) + 1, 1);
    pdf[1] := 0;
    pdf[2:length(xvals)] := exp(-mean) * mean^xvals[2:length(xvals)]/
      private.factorial(xvals[2:length(xvals)]);
    private.plotter.sci(3);
    private.plotter.pt(xvals, nsamples*pdf, 19);
    private.plotter.sci(1);
    private.plotter.lab('', '', 'Poisson distribution');
  }

  const public.binomial := function(number, probability) {
    wider private;
    const nsamples := 1E4;
    const binsperint := 5;
    const data := private.rand.binomial(number, probability, nsamples);
    const minx := as_integer(min(data)) - 1 - 0.5/binsperint;
    const maxx := as_integer(max(data)) + 1 + 0.5/binsperint;
    private.plotter.hist(data, minx, maxx, (maxx - minx)*binsperint, 0);
    const xvals := seq(-1, number + 1, 1);
    pdf := array(0, 1, length(xvals));
    const xv := xvals[2:(length(xvals)-1)];
    pdf[2:(length(xvals)-1)] := private.factorial(number)/
      private.factorial(xv)/private.factorial(number-xv) * 
	probability^xv * (1-probability)^(number-xv);
    private.plotter.sci(3);
    private.plotter.pt(xvals, nsamples*pdf, 19);
    private.plotter.sci(1);
    private.plotter.lab('', '', 'Binomial distribution');
  }

  const public.geometric := function(probability) {
    wider private;
    const nsamples := 1E4;
    const binsperint := 4;
    const data := private.rand.geometric(probability, nsamples);
    const minx := as_integer(min(data)) - 1 - 0.5/binsperint;
    const maxx := as_integer(max(data)) + 1 + 0.5/binsperint;
    private.plotter.hist(data, minx, maxx, (maxx - minx)*binsperint, 0);
    const xvals := seq(-1, max(data) + 1, 1);
    pdf := array(0, 1, length(xvals));
    const xv := xvals[2:length(xvals)];
    pdf[2:length(xvals)] := probability * (1-probability)^xv;
    private.plotter.sci(3);
    private.plotter.pt(xvals, nsamples*pdf, 19);
    private.plotter.sci(1);
    private.plotter.lab('', '', 'Geometric distribution');
  }

  const public.hypergeometric := function(mean, variance) {
    wider private;
    const nsamples := 1E4;
    const data := private.rand.hypergeometric(mean, variance, nsamples);
    const minx := as_integer(min(data)) - 1;
    const maxx := as_integer(max(data)) + 1;
    private.plotter.hist(data, minx, maxx, maxx - minx, 0);
    private.plotter.lab('', '', 'Hypergeometric distribution');
  }

  const public.erlang := function(mean, variance) {
    wider private;
    const nsamples := 1E4;
    const data := private.rand.erlang(mean, variance, nsamples);
    const minx := as_integer(min(data)) - 1;
    const maxx := as_integer(max(data)) + 1;
    private.plotter.hist(data, minx, maxx, maxx - minx, 0);
    const beta := variance/mean;
    const alphap1 := mean/beta;
    const xvals := seq(minx, maxx, .1);
    const xv := xvals[xvals > 0];
# this is not exact, as the pdf needs to be divided by
# Gamma(alphap1). But I was not going to program a table of values for
# the Gamma function and for alphap1 between 1 and 2 its near 1.0;
    pdf := array(0.0, length(xvals));
    const pdf[xvals > 0] := xv^(alphap1 - 1) * exp(-xv/beta)/(beta^alphap1);
    if (abs(alphap1 - 2) > 1E-5 && abs(alphap1 - 1) > 1E-5) {
      note('Gamma(', alphap1, ') is assumed to be 1.0, but it isn\'t ',
	   '(Gamma(1) and Gamma(2) are 1.0)\n', 
	   'Theoretical pdf will be inaccurate',
	   priority='WARN', origin='drandomnumbers.erlang');
    }
    private.plotter.sci(3);
    private.plotter.line(xvals, nsamples*pdf) ;
    private.plotter.sci(1);
    private.plotter.lab('', '', 'Erlang distribution');
  }

  const public.lognormal := function(mean, variance) {
    wider private;
    const nsamples := 1E4;
    const data := private.rand.lognormal(mean, variance, nsamples);
    const minx := as_integer(min(data)) - 1;
    const maxx := as_integer(max(data)) + 1;
    private.plotter.hist(data, minx, maxx, maxx - minx, 0);
    private.plotter.lab('', '', 'Log-normal distribution');
  }

  const public.negativeexponential := function(mean) {
    wider private;
    const nsamples := 1E4;
    const data := private.rand.negativeexponential(mean, nsamples);
    const minx := as_integer(min(data)) - 1;
    const maxx := as_integer(max(data)) + 1;
    private.plotter.hist(data, minx, maxx, maxx - minx, 0);
    const xvals := seq(minx, maxx, .1);
    pdf := exp(-(xvals/mean))/mean;
    pdf[xvals < 0] := 0;
    private.plotter.sci(3);
    private.plotter.line(xvals, nsamples*pdf) ;
    private.plotter.sci(1);
    private.plotter.lab('', '', 'Negative exponential distribution');
  }

  const public.weibull := function(alpha, beta) {
    wider private;
    const nsamples := 1E4;
    const data := private.rand.weibull(alpha, beta, nsamples);
    const minx := as_integer(min(data)) - 1;
    const maxx := as_integer(max(data)) + 1;
    private.plotter.hist(data, minx, maxx, maxx - minx, 0);
    private.plotter.lab('', '', 'Weibull distribution');
  }

  const public.example:= function() {
    note('Example usage of the randomnumbers tool',origin='randomnumbersdemo');
    note('include \'randomnubers.g\'', origin='randomnumbersdemo');
    note('server := randomnumbers()', origin='randomnumbersdemo');
    result := private.rand.normal();
    note('result := server.normal()\n', 
         '# result=', as_string(result),
         origin='randomnumbersdemo');
    result := private.rand.normal(shape=5);
    note('result := server.normal(shape=5)\n', 
         '# result=', as_string(result),
         origin='randomnumbersdemo');
    
    result := private.rand.normal(mean=5,variance=0.01, shape=3);
    note('result := server.normal(mean=5,variance=0.01,shape=3)\n',
         '# result=', as_string(result),
         origin='randomnumbersdemo');
    
    private.rand.reseed(0); result := private.rand.normal();
    note('server.reseed(0); result := server.normal()\n', 
         '# result=', as_string(result),
         origin='randomnumbersdemo');
    private.rand.reseed(2); result := private.rand.normal();
    note('server.reseed(2); result := server.normal()\n', 
         '# result=', as_string(result),
         origin='randomnumbersdemo');
    note('server.done();', origin='randomnumbersdemo');
    return T;
  }

  const public.done  := function() {
    wider private, public;
    private.rand.done();
    val private := F;
    val public := F;
    return T;
  }

  return ref public
}
