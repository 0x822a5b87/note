/**
 * @author hangyudu
 * @date 2020/2/9
 */
public class Ognl {

    private int sayHello() {
        System.out.println("mc hello world");
        return 0;
    }

    public static void main(String[] args) {
        Ognl ognl = new Ognl();
        while (true) {
            try {
                ognl.sayHello();
                Thread.sleep(1000);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }
    }
}
