% Shameless Port of Krishnamoorthy's "Two Poisson Means" fortran code
% 
% Port by Andrew Leifer
% leifer@princeton.edu
% 24 January 2018 
%
% Fortran program: computes the p-value for testing the difference between 
% two Poisson means. [Source: Krishnamoorthy, K and Thomson, J. (2004) 
% A more powerful test for comparing two Poisson means. Journal of 
% Statistical Planning and Inference, 119, 249-267]
%
% Original Code http://www.ucs.louisiana.edu/~kxk4695/
% and http://www.ucs.louisiana.edu/~kxk4695/statcalc/pois2pval.for
%
% ccccccccccccccccccccccccc cccccccccccccccccccccccccccccccccccccccccccccccccccc
% c Main program: computes the p-value of the unconditional test for testing
% c one and two-sided hypotheses about the means of two Poisson
% c distributions.
% c
% c INPUT:
% c iside = side of the test; 1 for right-sided, 2 for two-sided
% c alpha = nominal level of the test
% c ki = count of the ith population, i = 1,2
% c ni = sample size from the ith population, i=1,2
% c d = the difference mean1 - mean2 under the H0
% c
% c OUTPUT:
% c p-value = p-value of the unconditional test
% ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc


function pvalue=testPoissonSignificance(k1,k2,n1,n2,d,iside)
% function pvalue=testPoissonSignificance(k1,k2,n1,n2,d,iside)
%
%  k1, k2   = sample counts (must be integer)
%  n1, n2   = sample size (must be integer)
%  d        = value of mean1-mean2 under H0  (default is zero)
%  iside    = 1 for right tail-test or 2 for two-tail test (default)
%
% Shameless Port of Krishnamoorthy's "Two Poisson Means" fortran code
% 
% Port by Andrew Leifer
% leifer@princeton.edu
% 24 January 2018 
%
% Fortran program: computes the p-value for testing the difference between 
% two Poisson means. [Source: Krishnamoorthy, K and Thomson, J. (2004) 
% A more powerful test for comparing two Poisson means. Journal of 
% Statistical Planning and Inference, 119, 249-267]
%
% Original Code http://www.ucs.louisiana.edu/~kxk4695/
% and http://www.ucs.louisiana.edu/~kxk4695/statcalc/pois2pval.for

%Later:
%  make d and iside optional and give them default values
% enforce that k1 and k2 and n1 and n2 are integers

    assert(iside==1|| iside==2);

    if (k1 == 0) && (k2 == 0)
        %special case of no observations
        pvalue=1;
        return
    end

	elhatk = (k1+k2)/(n1+n2)-d*n1/(n1+n2);
	
    var = (k1/ (n1^2) + k2/(n2^2));
	
    t_k1k2 = (k1/n1-k2/n2-d)/sqrt(var);
    
	pvalue=poistest(iside, n1, n2, elhatk, t_k1k2, d);
    
end


% cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
% c Program for computing the p-value of the unconditional test
% c In the first subroutine, the sum over i1 is carried out
% cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

function pvalue=poistest(iside, n1, n2, elhatk, t_k1k2, d)
% computing estimates of el1*n1 and el2*n2 under H_0
    pvalue=0; 
    elhat1=n1*(elhatk+d);
	elhat2 = n2*elhatk;
        


% computing the modes 
	i1mode = floor(elhat1);
	i2mode = floor(elhat2);
    
% initializing the probability at the i1mode
	pi1mode = poipr(i1mode, elhat1);
	pi1 = pi1mode;

    
% initializing the probability at the i2mode
	pi2mode = poipr(i2mode, elhat2)    ;
        
    
    for i1=[i1mode:1000] 
        if (pi1 < 1e-7)       
          break;  
        end
        pvalue=sumi2(iside, n1, n2, elhat2, t_k1k2, i1, pi1, i2mode, pi2mode, d,pvalue);
	  pi1 = elhat1*pi1/(i1+1);
    end 

    

    %Label #1 
    i1 = i1mode-1;
    pi1 = pi1mode;
	pi1 = i1mode*pi1/elhat1;
	
	for i1 = [i1mode-1:-1: 0]
	  if(pi1 < 1e-7) 
          return;
      end
	  pvalue=sumi2(iside, n1, n2, elhat2, t_k1k2, i1, pi1, i2mode, pi2mode, d,pvalue);
	  pi1 = i1*pi1/elhat1;
    end
	
  
end


% cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
% c Here, we carry out the sum over i2 to compute the p-value of the E-test 
% c
% cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
% 


function pvalue=sumi2(iside, n1, n2, elhat2, t_k1k2, i1, pi1, i2mode, pi2mode, d, pvalue)

	pi2 = pi2mode;

	for i2 = (i2mode:1000)
	  if(pi2 < 1.0e-07) 
          break
      end
	  elhati1 = 1.0e0*i1/n1;
	  elhati2 = 1.0e0*i2/n2;
      
	  diffi = elhati1 - elhati2 - d ;
	  var = (1.0e0*elhati1/n1 + 1.0e0*elhati2/n2);
	  if(iside == 1)     
        if(1.0e0*i1/n1 - 1.0e0*i2/n2 <= d)
	      t_i1i2 = 0.0e0;
        else
	      t_i1i2 = diffi/sqrt(var);
        end
	    if(t_i1i2 >= t_k1k2) 
            pvalue = pvalue + pi1*pi2;
        end
	  elseif(iside == 2)
	    if(abs(1.0e0*i1/n1 - 1.0e0*i2/n2) <= d) 
	      t_i1i2 = 0.0e0;
	    else
	      t_i1i2 = diffi/sqrt(var);
        end
	    if(abs(t_i1i2) >= abs(t_k1k2)) 
            pvalue = pvalue + pi1*pi2;
        end
      end
	  pi2 = elhat2*pi2/(i2+1.0e0);
	end

    i2 = i2mode-1 ;
	pi2 = pi2mode;
	pi2 = i2mode*pi2/elhat2;

	for i2 = ( (i2mode-1):-1:  0)
	  if(pi2 < 1.0e-07) 
          return
      end
	  elhati1 = 1.0e0*i1/n1;
	  elhati2 = 1.0e0*i2/n2;
	  diffi = elhati1 - elhati2 - d;
	  var = (1.0e0*elhati1/n1 + 1.0e0*elhati2/n2);
	  if(iside == 1) 
	    if(1.0e0*i1/n1 - 1.0e0*i2/n2 <= d) 
	      t_i1i2 = 0.0e0;
	    else
	      t_i1i2 = diffi/sqrt(var);
	    end 
	    if(t_i1i2 >= t_k1k2) 
            pvalue = pvalue + pi1*pi2;
        end
      elseif(iside == 2)     
	    if(abs(1.0e0*i1/n1 - 1.0e0*i2/n2) <= d) 
	      t_i1i2 = 0.0e0;
	    else
	      t_i1i2 = diffi/sqrt(var);
	    end 
	    if(abs(t_i1i2) >= abs(t_k1k2)) 
            pvalue = pvalue + pi1*pi2;
        end
	  end 
	  pi2 = i2*pi2/elhat2;
    end
	end







% ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
% c This program computes the P(X = k), where X is a Poisson random
% c variable with mean defective rate = el, # of defective items = k
% c
% ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

function prob = poipr(k, el)

    prob = poisspdf(k,el);
   
end




