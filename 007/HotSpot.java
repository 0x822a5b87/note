/**
 * @author hangyudu
 * @date 2020/2/11
 */
public class HotSpot {

    public void hotMethod() {
        try {
            Thread.sleep(1);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }

    public void invoke0() {
        hotMethod();
    }

    public void anotherInvoke() {
        hotMethod();
    }

    public void yetAnotherInvoke() {
        hotMethod();
    }

    public static void main(String[] args) {
        HotSpot sp = new HotSpot();
        while (true) {
            sp.invoke0();
            sp.anotherInvoke();;
            sp.yetAnotherInvoke();
        }
    }
}
