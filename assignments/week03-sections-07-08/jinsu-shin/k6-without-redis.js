import http from 'k6/http';
import { check } from 'k6';

export const options = {
  vus: 30,
  duration: '10s',
};

export default function () {
  const res = http.get('http://localhost:8081/boards?page=1&size=10');
  check(res, { 'status 200': (r) => r.status === 200 });
}
