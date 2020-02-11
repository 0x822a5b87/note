import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * @author hangyudu
 * @date 2020/2/11
 */
public class MultiThread {
    public static void main(String[] args) {
        ExecutorService service = Executors.newFixedThreadPool(100);
        for (int i = 0; i < 100; ++i) {
            service.execute(() -> {
                while (true) {
                    try {
                        Thread.sleep(10);
                    } catch (InterruptedException e) {
                        e.printStackTrace();
                    }
                }
            });
        }
    }
}
