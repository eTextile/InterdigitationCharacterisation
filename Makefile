
all:
	processing-java --sketch=$(CURDIR) --run &

clean:
	rm -f charact_*.png

xclean:
	git clean -f

# TODO: gif + csv (w/ error data + average)

############################################################
#
# Use arguments w/ Processing:
#
#  void setup() {
#    if (args != null) {
#      println(args.length);
#      for (int i = 0; i < args.length; i++) {
#        println(args[i]);
#      }
#  }
#
############################################################
#
# Command example:
#
#  $ processing-java --sketch=sketchname --run argu "arg o"
#    2
#    argu
#    arg o
#
############################################################

