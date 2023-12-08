rn = 0.3
if (rn < 0.5)
   disp('rn < 0.5')
else
   if (rn < 0.75)
      disp('rn >= 0.5 && rn < 0.75');
   else
      if (rn < 0.9)
         disp('rn >= 0.75 && rn < 0.9')
      else
         disp('rn >= 0.9')
      end
   end
end
