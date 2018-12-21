assert 'Hello World!' do
  begin
    t = TCC.new
    t.add_file './tmp.c', <<EOS
#include <stdio.h>
#include <stdlib.h>

int main() {
    FILE *fp = fopen("./tmp.txt", 'w');
    fprintf(fp, "Hello World!\n");
    return EXIT_SUCCESS;
}
EOS
    t.run

    assert_equal "Hello World!\n", File.read('./tmp.txt')
  ensure
    File.unlink './tmp.txt'
  end
end
